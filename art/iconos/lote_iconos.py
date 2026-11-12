"""Define el lote de iconos del juego (armas, reliquias, aumentos y kit de Orrun)
y escribe lote_iconos.json para tools/ia/generar_imagen.py.

    python art/iconos/lote_iconos.py
    python tools/ia/generar_imagen.py --lote art/iconos/lote_iconos.json --paralelo 3 --quality medium
"""

import json
import os

AQUI = os.path.dirname(os.path.abspath(__file__))

ESTILO = (
    "Square game icon for a dark fantasy action roguelike, hand-painted premium ARPG / MOBA icon style. "
    "Subject: {subject}. Composition: one bold centered subject filling most of the square, a strong readable "
    "silhouette even at 64 pixels, dramatic rim light, chunky stylized shapes, painterly texture. Background: "
    "dark moody painted background with a soft {glow} glow behind the subject and a darker vignette at the edges. "
    "Colors: {palette}. No text, no letters, no numbers, no frame, no border, no UI elements."
)

GLOWS = {
    "fisico": ("warm amber", "weathered grey-brown stone, moss green, amber highlights"),
    "hielo": ("icy cyan", "frosty white, pale cyan and deep blue"),
    "fuego": ("burning orange", "black tar, molten orange and ember red"),
    "rayo": ("electric yellow", "bright yellow, white-hot core and dark storm blue"),
    "sombra": ("violet", "deep violet, black smoke and magenta highlights"),
    "evolucion": ("radiant golden", "rich gold, white light and the element colors"),
    "reliquia": ("teal and gold", "aged bronze, teal gems and warm gold"),
    "eco": ("cool silver-blue", "silver, pale blue and stone grey"),
    "arcano": ("golden", "gold, amber and deep brown"),
    "mitico": ("purple", "royal purple, magenta and gold accents"),
    "kit": ("amber", "mossy grey-brown stone, rusty chains and glowing amber hexagonal runes"),
}

ICONOS = {
    "armas": {
        "puno_telurico": ("fisico", "a massive fist made of mossy stone plates with glowing amber hexagonal runes, punching forward with an amber shockwave"),
        "puno_del_monte": ("evolucion", "a colossal runed stone fist slamming the ground, a 360-degree amber seismic shockwave ring bursting outward, flying rocks"),
        "aura_gelida": ("hielo", "a swirling ring of frost and ice crystals around a glowing cyan core, freezing mist"),
        "cadena_de_escarcha": ("hielo", "a jagged bolt of frost lightning chaining between three sharp ice shards"),
        "campana_resonante": ("fisico", "an ancient runed bronze bell ringing, visible concentric sound shockwaves"),
        "campana_del_juicio": ("evolucion", "a huge golden judgement bell covered in glowing runes, a massive radiant shockwave, heavenly light"),
        "cuchillas_orbitales": ("fisico", "three curved steel blades orbiting in a circle with motion trails"),
        "danza_de_mil_filos": ("evolucion", "eight golden curved blades spinning in a perfect ring, golden sparks"),
        "esquirlas_umbrias": ("sombra", "sharp violet shadow crystal shards flying forward with dark smoke trails"),
        "tormenta_umbria": ("evolucion", "a vortex storm of many violet shadow shards bursting outward, golden edges"),
        "guadana_umbria": ("sombra", "a spectral shadow scythe slashing in a circular arc of violet smoke"),
        "minas_de_brea": ("fuego", "a bubbling black tar mine with glowing orange fire cracks about to explode"),
        "mortero_alquimico": ("fuego", "an alchemist bronze mortar launching a flaming glass flask in an arc"),
        "orbe_de_tormenta": ("rayo", "a crackling electric orb with yellow lightning arcs swirling around it"),
        "pararrayos": ("rayo", "a lightning bolt striking down from dark clouds onto an iron rod"),
    },
    "reliquias": {
        "amplitud": ("reliquia", "an ancient stone ring amulet radiating expanding circular waves"),
        "magnetismo": ("reliquia", "a horseshoe lodestone pulling small glowing green gems toward it"),
        "poder": ("reliquia", "a glowing red-orange runestone engraved with a clenched fist symbol"),
        "presteza": ("reliquia", "a winged bronze hourglass with flowing glowing sand"),
        "vigor": ("reliquia", "a heart-shaped red crystal pulsing with life in a carved stone setting"),
        "zancada": ("reliquia", "a winged stone boot with swift wind trails"),
    },
    "aumentos": {
        "cadena_de_mando": ("arcano", "a heavy rusted chain wrapped around a glowing hourglass"),
        "coloso": ("mitico", "a towering giant stone golem silhouette growing larger in front of a mountain"),
        "combustion": ("arcano", "a monster silhouette exploding into a burst of fire and embers"),
        "cristal_del_tiempo": ("mitico", "a cracked glowing time crystal surrounded by clock gears"),
        "espinas": ("arcano", "a stone shield covered in sharp red thorns reflecting a strike"),
        "filo_agudo": ("eco", "a gleaming razor-sharp sword edge with a bright spark of light"),
        "furia": ("arcano", "a roaring stone golem face with blazing red-orange eyes and flames of rage"),
        "impetu_eterno": ("mitico", "an endless amber energy spiral forming an infinity loop"),
        "multiplicidad_absoluta": ("mitico", "many duplicated glowing projectiles and blades fanning out from one point"),
        "ojo_avizor": ("eco", "a glowing golden eye with a sharp crosshair-shaped iris"),
        "paso_ligero": ("eco", "a light white feather above a stone footprint with swift wind lines"),
        "piel_de_corteza": ("eco", "thick tree bark armor plates over stone skin with green moss"),
        "sabiduria_antigua": ("eco", "an ancient open tome with glowing green gems floating above its pages"),
        "sed_de_batalla": ("arcano", "a stone gauntlet absorbing red life wisps"),
        "segundo_aliento": ("eco", "a green spirit flame rising from a cracked stone heart"),
        "todo_o_nada": ("mitico", "a spinning coin split between shining gold and blood red, high stakes"),
        "vampirismo": ("mitico", "crimson blood wisps flowing into a stone fist, dark red glow"),
    },
    "kit": {
        "raiz_profunda": ("kit", "massive stone golem feet rooted into the ground with layers of rock hardening around them"),
        "zancada_de_falla": ("kit", "a stone golem shoulder-charging forward leaving a glowing amber fault crack in the ground"),
        "despertar_del_monte": ("kit", "a mountain awakening with glowing amber runes, rocks erupting from huge earthquake shockwaves"),
        "paso": ("kit", "a quick dodging leap leaving a blurred stone afterimage and a dust burst"),
    },
}


def main():
    lote = []
    for carpeta, iconos in ICONOS.items():
        for nombre, (tipo, sujeto) in iconos.items():
            glow, palette = GLOWS[tipo]
            lote.append({
                "prompt": ESTILO.format(subject=sujeto, glow=glow, palette=palette),
                "out": os.path.join("art", "iconos", carpeta, nombre + ".png").replace("\\", "/"),
            })
    json.dump(lote, open(os.path.join(AQUI, "lote_iconos.json"), "w", encoding="utf-8"), indent=1, ensure_ascii=False)
    print(len(lote), "iconos")


main()
