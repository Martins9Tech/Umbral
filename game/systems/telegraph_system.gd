class_name TelegraphSystem
extends Node2D
## Ataques telegrafiados (GDD §7.1): una zona roja en el suelo se rellena hasta
## el momento del impacto y entonces daña a los jugadores que sigan dentro.
## Se pueden esquivar saliendo de la zona o con el Paso (invulnerable).
## Las zonas persistentes ("linger") dañan por segundo mientras duran.
## Se dibujan en el suelo (metros), por debajo de los personajes.

enum Shape { CIRCLE, CONE, LINE, SAFE_ZONES }

const DANGER := Color(1.0, 0.22, 0.12)
const SAFE := Color(0.3, 1.0, 0.45)
const LINGER_COLOR := Color(0.55, 0.15, 0.1)
const FLASH_TIME := 0.15
const DEFAULT_CAUSE := &"un ataque de la Madre Raíz"

var _items: Array[Dictionary] = []
var _time := 0.0


func count() -> int:
	return _items.size()


# --- Crear ---

func circle(center: Vector2, radius: float, delay: float, damage: float, linger: float = 0.0,
		linger_dps: float = 0.0, cause: StringName = DEFAULT_CAUSE) -> void:
	var item := _new_item(Shape.CIRCLE, delay, damage, linger, linger_dps)
	item["cause"] = cause
	item["center"] = center
	item["radius"] = radius


func cone(origin: Vector2, direction: Vector2, radius: float, half_angle: float, delay: float, damage: float) -> void:
	var item := _new_item(Shape.CONE, delay, damage)
	item["center"] = origin
	item["radius"] = radius
	item["direction"] = direction.normalized()
	item["half_angle"] = half_angle


func line(a: Vector2, b: Vector2, width: float, delay: float, damage: float) -> void:
	var item := _new_item(Shape.LINE, delay, damage)
	item["a"] = a
	item["b"] = b
	item["width"] = width


## Todo el área es peligrosa salvo las zonas seguras (verdes).
func safe_zones(area_center: Vector2, area_radius: float, safe_centers: PackedVector2Array,
		safe_radius: float, delay: float, damage: float) -> void:
	var item := _new_item(Shape.SAFE_ZONES, delay, damage)
	item["center"] = area_center
	item["radius"] = area_radius
	item["safe_centers"] = safe_centers
	item["safe_radius"] = safe_radius


func clear() -> void:
	_items.clear()
	queue_redraw()


# --- Simular ---

func tick(delta: float, run: Run) -> void:
	_time += delta
	queue_redraw()
	for k in range(_items.size() - 1, -1, -1):
		var item := _items[k]
		var state: StringName = item["state"]
		var time: float = item["time"]
		time += delta
		item["time"] = time
		match state:
			&"warning":
				var delay: float = item["delay"]
				if time >= delay:
					_resolve(item, run)
			&"linger":
				var dps: float = item["linger_dps"]
				for champion: Player in run.alive_players():
					if _contains(item, champion.pos):
						champion.take_damage(dps * delta, item["cause"])
				if time >= float(item["linger"]):
					_items.remove_at(k)
			&"flash":
				if time >= FLASH_TIME:
					_items.remove_at(k)


func _resolve(item: Dictionary, run: Run) -> void:
	var damage: float = item["damage"]
	if damage > 0.0:
		for champion: Player in run.alive_players():
			if _contains(item, champion.pos):
				champion.take_damage(damage, item["cause"])
	item["time"] = 0.0
	item["state"] = &"linger" if float(item["linger"]) > 0.0 else &"flash"


func _contains(item: Dictionary, p: Vector2) -> bool:
	var margin := Player.RADIUS
	match int(item["shape"]):
		Shape.CIRCLE:
			var center: Vector2 = item["center"]
			var radius: float = item["radius"]
			return p.distance_to(center) <= radius + margin
		Shape.CONE:
			var origin: Vector2 = item["center"]
			var radius: float = item["radius"]
			var offset := p - origin
			if offset.length() > radius + margin:
				return false
			if offset.length() < 1.0:
				return true
			var direction: Vector2 = item["direction"]
			return absf(direction.angle_to(offset)) <= float(item["half_angle"])
		Shape.LINE:
			var a: Vector2 = item["a"]
			var b: Vector2 = item["b"]
			var width: float = item["width"]
			return Geometry2D.get_closest_point_to_segment(p, a, b).distance_to(p) <= width * 0.5 + margin
		Shape.SAFE_ZONES:
			var center: Vector2 = item["center"]
			if p.distance_to(center) > float(item["radius"]):
				return false
			var safe_radius: float = item["safe_radius"]
			for safe_center: Vector2 in item["safe_centers"]:
				if p.distance_to(safe_center) <= safe_radius:
					return false
			return true
	return false


# --- Visual ---

func _new_item(shape: Shape, delay: float, damage: float, linger: float = 0.0, linger_dps: float = 0.0) -> Dictionary:
	var item := {
		"shape": shape, "delay": maxf(delay, 0.05), "damage": damage, "time": 0.0,
		"state": &"warning", "linger": linger, "linger_dps": linger_dps, "cause": DEFAULT_CAUSE,
	}
	_items.append(item)
	queue_redraw()
	return item


## Zona roja tenue + relleno que crece hasta el impacto; destello claro al
## golpear; rojo oscuro mientras persiste.
func _draw() -> void:
	for item: Dictionary in _items:
		var state: StringName = item["state"]
		var time: float = item["time"]
		match state:
			&"warning":
				var progress := clampf(time / float(item["delay"]), 0.02, 1.0)
				_draw_shape(item, 1.0, Color(DANGER, 0.2))
				_draw_shape(item, progress, Color(DANGER, 0.45))
				_draw_outline(item, Color(DANGER, 0.55 + 0.3 * sin(_time * 14.0)))
			&"linger":
				_draw_shape(item, 1.0, Color(LINGER_COLOR, 0.55))
			&"flash":
				_draw_shape(item, 1.0, Color(1.0, 0.85, 0.6, 0.8 * (1.0 - time / FLASH_TIME)))


func _draw_shape(item: Dictionary, grow: float, color: Color) -> void:
	match int(item["shape"]):
		Shape.CIRCLE:
			draw_circle(item["center"], float(item["radius"]) * grow, color)
		Shape.CONE:
			Draw2D.sector(self, item["center"], item["direction"], float(item["radius"]) * grow,
				float(item["half_angle"]), color)
		Shape.LINE:
			# La franja se ensancha desde su eje.
			Draw2D.band(self, item["a"], item["b"], float(item["width"]) * grow, color)
		Shape.SAFE_ZONES:
			draw_circle(item["center"], float(item["radius"]) * grow, color)
			for safe_center: Vector2 in item["safe_centers"]:
				draw_circle(safe_center, float(item["safe_radius"]), Color(SAFE, 0.55))
				Draw2D.ring(self, safe_center, float(item["safe_radius"]), 0.15, SAFE)


func _draw_outline(item: Dictionary, color: Color) -> void:
	match int(item["shape"]):
		Shape.CIRCLE, Shape.SAFE_ZONES:
			Draw2D.ring(self, item["center"], float(item["radius"]), 0.1, color)
		Shape.LINE:
			var a: Vector2 = item["a"]
			var b: Vector2 = item["b"]
			var side := (b - a).normalized().orthogonal() * float(item["width"]) * 0.5
			draw_line(a + side, b + side, color, 0.1)
			draw_line(a - side, b - side, color, 0.1)
