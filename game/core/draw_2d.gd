class_name Draw2D
extends RefCounted
## Ayudas de dibujo 2D compartidas (todo en las unidades locales del nodo que
## dibuja; en la partida son metros). Las sombras y anillos a los pies son
## elipses aplanadas: dan la sensación de suelo visto un poco en ángulo.

const RADIAL_SIZE := 256.0
## Aplanado vertical de sombras y anillos.
const FLAT := 0.45

static var _radial: GradientTexture2D
static var _soft: GradientTexture2D


## Degradado radial blanco -> transparente (luces, sombras, brillos).
static func radial_texture() -> Texture2D:
	if _radial == null:
		_radial = _gradient(Color(1, 1, 1, 1), Color(1, 1, 1, 0), 0.0)
	return _radial


## Disco de borde suave con núcleo sólido (proyectiles, chispas).
static func soft_disc_texture() -> Texture2D:
	if _soft == null:
		_soft = _gradient(Color(1, 1, 1, 1), Color(1, 1, 1, 0), 0.45)
	return _soft


static func ellipse(canvas: CanvasItem, center: Vector2, radius: float, color: Color, flat: float = FLAT) -> void:
	canvas.draw_set_transform(center, 0.0, Vector2(1.0, flat))
	canvas.draw_circle(Vector2.ZERO, radius, color)
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func ellipse_ring(canvas: CanvasItem, center: Vector2, radius: float, width: float, color: Color,
		flat: float = FLAT) -> void:
	canvas.draw_set_transform(center, 0.0, Vector2(1.0, flat))
	canvas.draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, color, width / flat * 0.7)
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func ring(canvas: CanvasItem, center: Vector2, radius: float, width: float, color: Color) -> void:
	canvas.draw_arc(center, radius, 0.0, TAU, maxi(24, int(radius * 12.0)), color, width)


## Piedra irregular (rocas del Rasgo, escombros).
static func rock(canvas: CanvasItem, at: Vector2, size: float, color: Color) -> void:
	var points := PackedVector2Array()
	for k in 6:
		var angle := TAU * k / 6.0 + 0.3
		var r := size * (0.8 + 0.25 * sin(k * 2.7 + at.x))
		points.append(at + Vector2(cos(angle) * r, sin(angle) * r * 0.75 - size * 0.4))
	canvas.draw_colored_polygon(points, color)
	canvas.draw_polyline(points + PackedVector2Array([points[0]]), color.darkened(0.55), size * 0.18)


## Textura apoyada en el suelo por su base (pies en `feet`), con un ancho en
## unidades locales. Devuelve la altura dibujada.
static func sprite(canvas: CanvasItem, texture: Texture2D, feet: Vector2, width: float, flip: bool = false,
		tint: Color = Color.WHITE) -> float:
	if texture == null:
		return 0.0
	var size := texture.get_size()
	var height := width * size.y / size.x
	canvas.draw_set_transform(feet, 0.0, Vector2(-1.0 if flip else 1.0, 1.0))
	canvas.draw_texture_rect(texture, Rect2(-width * 0.5, -height, width, height), false, tint)
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	return height


## Sector circular (conos de ataque).
static func sector(canvas: CanvasItem, origin: Vector2, direction: Vector2, radius: float, half_angle: float,
		color: Color) -> void:
	var points := PackedVector2Array([origin])
	var base := direction.angle()
	var segments := 24
	for s in segments + 1:
		var a := base - half_angle + 2.0 * half_angle * s / segments
		points.append(origin + Vector2.from_angle(a) * radius)
	canvas.draw_colored_polygon(points, color)


## Franja de a hasta b con un ancho dado.
static func band(canvas: CanvasItem, a: Vector2, b: Vector2, width: float, color: Color) -> void:
	var d := b - a
	if d.length_squared() < 0.0001:
		return
	var side := d.normalized().orthogonal() * width * 0.5
	canvas.draw_colored_polygon(PackedVector2Array([a + side, b + side, b - side, a - side]), color)


## Rectángulo texturizado para MultiMesh 2D. `anchor` es el punto de la
## textura (u, v) que queda en el origen (p. ej. los pies: (0.5, 0.96)).
static func quad_mesh(size: Vector2, anchor: Vector2 = Vector2(0.5, 0.5)) -> ArrayMesh:
	var top_left := -anchor * size
	var vertices := PackedVector2Array([top_left, top_left + Vector2(size.x, 0.0),
		top_left + size, top_left + Vector2(0.0, size.y)])
	var uvs := PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2, 0, 2, 3])
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## MultiMesh 2D listo para escribir su buffer a mano. `area` es la zona donde
## pueden estar sus instancias (la arena): sin ella, Godot calcula el área
## visible una sola vez, al primer dibujado, y deja de dibujarlas al alejarse.
static func multimesh_2d(mesh: Mesh, max_count: int, colors: bool, custom: bool, area: Rect2) -> MultiMesh:
	var multimesh := MultiMesh.new()
	var grown := area.grow(10.0)
	multimesh.custom_aabb = AABB(Vector3(grown.position.x, grown.position.y, -1.0), Vector3(grown.size.x, grown.size.y, 2.0))
	multimesh.transform_format = MultiMesh.TRANSFORM_2D
	multimesh.use_colors = colors
	multimesh.use_custom_data = custom
	multimesh.mesh = mesh
	multimesh.instance_count = max_count
	multimesh.visible_instance_count = 0
	return multimesh


## Escribe una transformación 2D (rotación + escala + posición) en un buffer de MultiMesh.
static func write_xform(buffer: PackedFloat32Array, b: int, origin: Vector2, rot: float, sx: float, sy: float) -> void:
	var c := cos(rot)
	var s := sin(rot)
	buffer[b] = c * sx
	buffer[b + 1] = -s * sy
	buffer[b + 2] = 0.0
	buffer[b + 3] = origin.x
	buffer[b + 4] = s * sx
	buffer[b + 5] = c * sy
	buffer[b + 6] = 0.0
	buffer[b + 7] = origin.y


static func _gradient(inner: Color, outer: Color, core: float) -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, inner)
	g.set_color(1, outer)
	if core > 0.0:
		g.add_point(core, inner)
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(0.5, 0.0)
	t.width = int(RADIAL_SIZE)
	t.height = int(RADIAL_SIZE)
	return t
