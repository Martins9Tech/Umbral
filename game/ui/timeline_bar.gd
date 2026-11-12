class_name TimelineBar
extends Control
## Barra de la línea de tiempo del mapa: progreso hasta el jefe y marcas de
## los eventos (élites, Heraldo, estampida, jefe).

const ELITE_COLOR := Color(1.0, 0.6, 0.25)
const HERALD_COLOR := Color(1.0, 0.35, 0.3)
const BOSS_COLOR := Color(0.55, 1.0, 0.4)
const AUGMENT_COLOR := Color(0.88, 0.45, 1.0)

var _progress := 0.0
var _events: Array = []
var _total := 600.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func setup(events: Array, total: float) -> void:
	_events = events
	_total = total
	queue_redraw()


func set_progress(elapsed: float) -> void:
	var value := clampf(elapsed / _total, 0.0, 1.0)
	if not is_equal_approx(value, _progress):
		_progress = value
		queue_redraw()


func _draw() -> void:
	var mid := size.y * 0.5
	draw_rect(Rect2(0.0, mid - 4.0, size.x, 8.0), Color(0.05, 0.05, 0.08, 0.85))
	draw_rect(Rect2(0.0, mid - 4.0, size.x * _progress, 8.0), Color(0.75, 0.75, 0.85, 0.9))
	for event: Dictionary in _events:
		var x := size.x * float(event["time"]) / _total
		var passed := float(event["time"]) / _total <= _progress
		var alpha := 0.35 if passed else 1.0
		match event["kind"]:
			&"elite":
				draw_circle(Vector2(x, mid), 5.0, Color(ELITE_COLOR, alpha))
			&"herald":
				_diamond(Vector2(x, mid), 9.0, Color(HERALD_COLOR, alpha))
			&"augment":
				draw_rect(Rect2(x - 6.0, mid - 6.0, 12.0, 12.0), Color(AUGMENT_COLOR, alpha))
			&"altar", &"merchant", &"contract":
				var event_color: Color = InteractableSystem.COLORS[{&"altar": InteractableSystem.Kind.ALTAR, &"merchant": InteractableSystem.Kind.MERCHANT, &"contract": InteractableSystem.Kind.CONTRACT}[event["kind"]]]
				draw_colored_polygon(PackedVector2Array([Vector2(x, mid - 8.0), Vector2(x + 7.0, mid + 6.0), Vector2(x - 7.0, mid + 6.0)]), Color(event_color, alpha))
			&"stampede":
				draw_circle(Vector2(x, mid), 6.0, Color(HERALD_COLOR, alpha))
			&"boss":
				_diamond(Vector2(x, mid), 12.0, Color(BOSS_COLOR, alpha))
	# Posición actual
	var now := size.x * _progress
	draw_rect(Rect2(now - 2.0, mid - 11.0, 4.0, 22.0), Color.WHITE)


func _diamond(at: Vector2, radius: float, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([
		at + Vector2(0.0, -radius), at + Vector2(radius, 0.0),
		at + Vector2(0.0, radius), at + Vector2(-radius, 0.0)]), color)
