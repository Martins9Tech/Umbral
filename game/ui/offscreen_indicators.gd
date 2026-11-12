class_name OffscreenIndicators
extends Control
## Flechas en el borde de la pantalla que señalan objetivos fuera de la vista
## (élites, cofres). Si el objetivo está en pantalla, dibuja una marca encima.

const EDGE_MARGIN := 46.0
const ARROW_SIZE := 24.0

## Nodo del mundo de la partida (escalado a píxeles): convierte metros a pantalla.
var _world: Node2D
var _targets: Array[Dictionary] = []  # {world: Vector3(x, altura, y) en metros, color, label}
var _time := 0.0


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_targets(world: Node2D, targets: Array[Dictionary]) -> void:
	_world = world
	_targets = targets
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta


func _draw() -> void:
	if _world == null:
		return
	var to_screen := _world.get_global_transform_with_canvas()
	var rect := get_viewport().get_visible_rect()
	var inner := rect.grow(-EDGE_MARGIN)
	var center := rect.get_center()
	var font := ThemeDB.fallback_font
	var bob := 6.0 * sin(_time * 5.0)
	for target: Dictionary in _targets:
		var world: Vector3 = target["world"]
		var color: Color = target["color"]
		var text: String = target["label"]
		# La altura (y) sube el punto en pantalla: la marca flota sobre la cabeza.
		var screen := to_screen * Vector2(world.x, world.z - world.y)
		if inner.has_point(screen):
			# En pantalla: rombo que flota encima del objetivo.
			var top := screen + Vector2(0.0, -70.0 + bob)
			_draw_diamond(top, 14.0, color)
			draw_string(font, top + Vector2(-120.0, -18.0), text, HORIZONTAL_ALIGNMENT_CENTER, 240.0, 21, color)
			continue
		# Fuera de pantalla: flecha en el borde, en la dirección del objetivo.
		var direction := (screen - center)
		if direction.length_squared() < 1.0:
			direction = Vector2.DOWN
		direction = direction.normalized()
		var edge := _clamp_to_rect(center, direction, inner)
		var tip := edge + direction * ARROW_SIZE
		var side := direction.orthogonal() * ARROW_SIZE * 0.7
		draw_colored_polygon(PackedVector2Array([tip, edge - side, edge + side]), color)
		draw_string(font, edge - direction * 30.0 + Vector2(-120.0, 6.0), text, HORIZONTAL_ALIGNMENT_CENTER, 240.0, 21, color)


func _draw_diamond(at: Vector2, radius: float, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([
		at + Vector2(0.0, -radius), at + Vector2(radius, 0.0),
		at + Vector2(0.0, radius), at + Vector2(-radius, 0.0)]), color)


func _clamp_to_rect(origin: Vector2, direction: Vector2, rect: Rect2) -> Vector2:
	var t := INF
	if direction.x > 0.0001:
		t = minf(t, (rect.end.x - origin.x) / direction.x)
	elif direction.x < -0.0001:
		t = minf(t, (rect.position.x - origin.x) / direction.x)
	if direction.y > 0.0001:
		t = minf(t, (rect.end.y - origin.y) / direction.y)
	elif direction.y < -0.0001:
		t = minf(t, (rect.position.y - origin.y) / direction.y)
	return origin + direction * t
