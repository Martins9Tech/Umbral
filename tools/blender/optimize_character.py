"""Optimiza un personaje generado por IA para el juego (TECNICO §5.1).

- Junta las animaciones de varios GLB que comparten esqueleto en un solo modelo.
- Reduce la malla al número de triángulos objetivo (conserva los pesos del rig).
- Conecta una textura emisiva (runas, ojos) si se indica.
- Reduce las texturas al tamaño indicado.
- Deja las animaciones en el sitio (sin deriva del hueso raíz), salvo las de
  --keep-root-motion (caídas y muerte).
- Usa el GLB que lleva esqueleto (en Hyper3D, base_basic_pbr.glb).
- Exporta un único GLB con todas las animaciones (una pista NLA por animación).

Uso (Blender en segundo plano):
    blender -b --python tools/blender/optimize_character.py -- \
        --glb A.glb B.glb --emissive texture_emissive.png \
        --out art/modelos/orrun/orrun.glb --tris 15000 --tex 1024
"""

import argparse
import sys

import bpy


def parse_args():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--glb", nargs="+", required=True)
    parser.add_argument("--emissive", default="")
    parser.add_argument("--emissive-strength", type=float, default=4.0)
    parser.add_argument("--out", required=True)
    parser.add_argument("--tris", type=int, default=15000)
    parser.add_argument("--tex", type=int, default=1024)
    parser.add_argument("--root-bone", default="Hips")
    # Animaciones (por fragmento de nombre) que conservan su desplazamiento propio.
    # El resto se deja "en el sitio": el juego mueve al personaje, no la animación.
    parser.add_argument("--keep-root-motion", nargs="*", default=["Dying", "Fall"])
    return parser.parse_args(argv)


def action_fcurves(action):
    """F-curves de una acción (Blender 5 usa acciones por capas)."""
    curves = []
    for layer in getattr(action, "layers", []):
        for strip in layer.strips:
            for bag in strip.channelbags:
                curves.extend(bag.fcurves)
    return curves or list(getattr(action, "fcurves", []))


def make_in_place(action, root_bone):
    """Quita la deriva lineal de la posición del hueso raíz (avance al correr,
    hundimiento) para que la animación empiece y acabe en el mismo punto."""
    path = f'pose.bones["{root_bone}"].location'
    for fc in action_fcurves(action):
        if fc.data_path != path or len(fc.keyframe_points) < 2:
            continue
        keys = fc.keyframe_points
        t0, v0 = keys[0].co
        t1, v1 = keys[-1].co
        if t1 <= t0:
            continue
        slope = (v1 - v0) / (t1 - t0)
        for key in keys:
            shift = slope * (key.co[0] - t0)
            key.co[1] -= shift
            key.handle_left[1] -= shift
            key.handle_right[1] -= shift
        fc.update()


def triangle_count(mesh_obj):
    mesh = mesh_obj.data
    mesh.calc_loop_triangles()
    return len(mesh.loop_triangles)


def main():
    args = parse_args()
    bpy.ops.wm.read_factory_settings(use_empty=True)

    # 1. El primer GLB aporta malla, esqueleto y sus animaciones.
    bpy.ops.import_scene.gltf(filepath=args.glb[0])
    base_objects = set(bpy.context.scene.objects)
    armature = next(o for o in base_objects if o.type == "ARMATURE")
    mesh_obj = next(o for o in base_objects if o.type == "MESH")

    # 2. Los demás GLB solo aportan animaciones (mismo esqueleto): se importan y se borran sus objetos.
    for extra in args.glb[1:]:
        before = set(bpy.context.scene.objects)
        bpy.ops.import_scene.gltf(filepath=extra)
        for obj in set(bpy.context.scene.objects) - before:
            bpy.data.objects.remove(obj, do_unlink=True)

    # Objetos sueltos que trae el GLB (p. ej. una esfera de previsualización).
    for obj in list(bpy.context.scene.objects):
        if obj.type == "MESH" and obj is not mesh_obj:
            print(f"[OPT] quitado objeto suelto: {obj.name}")
            bpy.data.objects.remove(obj, do_unlink=True)

    # 3. Cada animación pasa a ser una pista NLA del esqueleto base (el exportador
    #    crea una animación por pista). Se quitan duplicados por nombre.
    if armature.animation_data is None:
        armature.animation_data_create()
    anim_data = armature.animation_data
    anim_data.action = None
    for track in list(anim_data.nla_tracks):
        anim_data.nla_tracks.remove(track)
    seen = set()
    for action in sorted(bpy.data.actions, key=lambda a: a.name):
        name = action.name.split(".")[0]
        if name in seen:
            continue
        seen.add(name)
        if not any(part in name for part in args.keep_root_motion):
            make_in_place(action, args.root_bone)
        track = anim_data.nla_tracks.new()
        track.name = name
        start = int(action.frame_range[0])
        strip = track.strips.new(name, start, action)
        if hasattr(strip, "action_slot") and strip.action_slot is None and len(getattr(action, "slots", [])) > 0:
            strip.action_slot = action.slots[0]
        track.mute = False
    print(f"[OPT] animaciones: {sorted(seen)}")

    # 4. Reducir la malla (antes que el modificador de esqueleto, para conservar los pesos).
    before_tris = triangle_count(mesh_obj)
    ratio = min(1.0, args.tris / max(before_tris, 1))
    bpy.context.view_layer.objects.active = mesh_obj
    mesh_obj.select_set(True)
    decimate = mesh_obj.modifiers.new("Decimate", "DECIMATE")
    decimate.ratio = ratio
    decimate.use_collapse_triangulate = True
    while mesh_obj.modifiers.find("Decimate") > 0:
        bpy.ops.object.modifier_move_up(modifier="Decimate")
    bpy.ops.object.modifier_apply(modifier="Decimate")
    print(f"[OPT] triángulos: {before_tris:,} -> {triangle_count(mesh_obj):,}")

    # 5. Textura emisiva conectada al material (las runas brillarán en Godot).
    if args.emissive:
        image = bpy.data.images.load(args.emissive)
        for material in mesh_obj.data.materials:
            nodes = material.node_tree.nodes
            bsdf = next((n for n in nodes if n.type == "BSDF_PRINCIPLED"), None)
            if bsdf is None:
                continue
            tex = nodes.new("ShaderNodeTexImage")
            tex.image = image
            material.node_tree.links.new(tex.outputs["Color"], bsdf.inputs["Emission Color"])
            bsdf.inputs["Emission Strength"].default_value = args.emissive_strength
        print("[OPT] textura emisiva conectada")

    # 6. Texturas más pequeñas.
    for image in bpy.data.images:
        if image.size[0] > args.tex or image.size[1] > args.tex:
            image.scale(args.tex, args.tex)
            image.pack()
    print(f"[OPT] texturas a {args.tex} px")

    # 7. Exportar un único GLB con todas las animaciones.
    bpy.ops.export_scene.gltf(
        filepath=args.out,
        export_format="GLB",
        export_animation_mode="NLA_TRACKS",
        export_yup=True,
    )
    print(f"[OPT] exportado: {args.out}")


main()
