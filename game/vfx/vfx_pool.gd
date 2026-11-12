class_name VfxPool
extends Node2D
## Efectos reutilizables dibujados en 2D (metros): discos y franjas en el suelo
## que se desvanecen, y rayos que caen del cielo. Los rayos van a la capa
## superior (`top`) para verse por encima de la horda.

const POOL_SIZE := 96
const DISC := 0
const LINE := 1
const BOLT := 2

## Capa de efectos por encima de los personajes (la asigna Run).
var top: VfxPool

var _items: Array[Dictionary] = []
var _next := 0
var _active := 0


func _ready() -> void:
	for _k in POOL_SIZE:
		_items.append({"kind": DISC, "a": Vector2.ZERO, "b": Vector2.ZERO, "size": 1.0,
			"time": 0.0, "duration": 1.0, "color": Color.WHITE, "alive": false})


func disc(center: Vector2, radius: float, color: Color, duration: float) -> void:
	_start(DISC, center, Vector2.ZERO, radius, color, duration)


func line(a: Vector2, b: Vector2, width: float, color: Color, duration: float) -> void:
	_start(LINE, a, b, width, color, duration)


## Rayo vertical que cae del cielo sobre un punto.
func bolt(at: Vector2, color: Color, duration: float) -> void:
	if top != null:
		top.bolt(at, color, duration)
		return
	_start(BOLT, at, Vector2.ZERO, 0.35, color, duration)


func tick(delta: float) -> void:
	_active = 0
	for item: Dictionary in _items:
		if not item["alive"]:
			continue
		var time: float = item["time"]
		time += delta
		item["time"] = time
		if time >= float(item["duration"]):
			item["alive"] = false
			continue
		_active += 1
	queue_redraw()
	if top != null:
		top.tick(delta)


func _draw() -> void:
	for item: Dictionary in _items:
		if not item["alive"]:
			continue
		var k: float = float(item["time"]) / float(item["duration"])
		var color: Color = item["color"]
		var fade := color.a * (1.0 - k)
		var a: Vector2 = item["a"]
		var size: float = item["size"]
		match int(item["kind"]):
			DISC:
				draw_circle(a, size, Color(color, fade * 0.7))
				Draw2D.ring(self, a, size, maxf(0.08, size * 0.05), Color(color.lightened(0.3), fade))
			LINE:
				Draw2D.band(self, a, item["b"], size, Color(color, fade))
			BOLT:
				var sky := a + Vector2(0.4, -9.0)
				var mid := a.lerp(sky, 0.5) + Vector2(-0.5, 0.0)
				draw_polyline(PackedVector2Array([sky, mid, a]), Color(color, fade * 0.5), size * 2.2)
				draw_polyline(PackedVector2Array([sky, mid, a]), Color(1, 1, 1, fade), size * 0.7)
				draw_circle(a, 0.6, Color(color, fade * 0.6))


func _start(kind: int, a: Vector2, b: Vector2, size: float, color: Color, duration: float) -> void:
	var item := _items[_next]
	_next = (_next + 1) % POOL_SIZE
	# Intensidad de los efectos (ajustes de accesibilidad).
	color.a *= float(SaveManager.setting("vfx_intensity"))
	item["kind"] = kind
	item["a"] = a
	item["b"] = b
	item["size"] = size
	item["color"] = color
	item["time"] = 0.0
	item["duration"] = maxf(duration, 0.01)
	item["alive"] = true
