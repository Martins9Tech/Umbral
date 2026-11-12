class_name InteractableSystem
extends Node2D
## Puntos del mapa con los que se interactúa al acercarse (GDD §5.7-5.8):
## mercader, altar de sangre y piedra de contrato. Duran un tiempo limitado.
## Dibujo 2D provisional (en metros) hasta tener su arte.

enum Kind { MERCHANT, ALTAR, CONTRACT }

const TRIGGER_RADIUS := 2.4
const RETRIGGER_COOLDOWN := 4.0
const LABELS := {Kind.MERCHANT: "MERCADER", Kind.ALTAR: "ALTAR", Kind.CONTRACT: "CONTRATO"}
const COLORS := {
	Kind.MERCHANT: Color(1.0, 0.82, 0.3),
	Kind.ALTAR: Color(1.0, 0.25, 0.25),
	Kind.CONTRACT: Color(0.35, 0.9, 1.0),
}

var _items: Array[Dictionary] = []  # {kind, pos, time_left, cooldown, time}
var _textures := {}
## Arte de cada punto y su ancho en metros.
const ART := {Kind.MERCHANT: ["mercader", 3.8], Kind.ALTAR: ["altar", 2.0], Kind.CONTRACT: ["contrato", 1.5]}


func spawn(kind: Kind, p: Vector2, lifetime: float) -> void:
	_items.append({"kind": kind, "pos": p, "time_left": lifetime, "cooldown": 0.0, "time": 0.0})


## Devuelve el tipo del punto que un jugador acaba de tocar (o -1), y lo
## deja en enfriamiento para no reabrirlo enseguida.
func tick(delta: float, players: Array[Player]) -> int:
	var triggered := -1
	queue_redraw()
	for k in range(_items.size() - 1, -1, -1):
		var item := _items[k]
		var time_left: float = item["time_left"]
		time_left -= delta
		item["time_left"] = time_left
		var cooldown: float = item["cooldown"]
		item["cooldown"] = maxf(0.0, cooldown - delta)
		var time: float = item["time"]
		time += delta
		item["time"] = time
		if time_left <= 0.0:
			_items.remove_at(k)
			continue
		if triggered >= 0 or float(item["cooldown"]) > 0.0:
			continue
		var p: Vector2 = item["pos"]
		for player: Player in players:
			if not player.is_dead() and player.pos.distance_to(p) <= TRIGGER_RADIUS:
				triggered = int(item["kind"])
				item["cooldown"] = RETRIGGER_COOLDOWN
				break
	return triggered


func remove_kind(kind: Kind) -> void:
	for k in range(_items.size() - 1, -1, -1):
		if int(_items[k]["kind"]) == kind:
			_items.remove_at(k)


func has_kind(kind: Kind) -> bool:
	for item: Dictionary in _items:
		if int(item["kind"]) == kind:
			return true
	return false


## Para las flechas del HUD: {world, color, label}.
func indicator_targets() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for item: Dictionary in _items:
		var p: Vector2 = item["pos"]
		var kind: int = item["kind"]
		out.append({"world": Vector3(p.x, 3.5, p.y), "color": COLORS[kind],
			"label": "%s %ds" % [LABELS[kind], ceili(float(item["time_left"]))]})
	return out


func clear() -> void:
	_items.clear()


## Mercader (carromato con toldo), altar (pilar con orbe rojo) y contrato
## (losa con orbe cian), con el círculo de activación en el suelo.
func _draw() -> void:
	for item: Dictionary in _items:
		var kind: int = item["kind"]
		var p: Vector2 = item["pos"]
		var time: float = item["time"]
		var color: Color = COLORS[kind]
		var stone := Color(0.3, 0.26, 0.26)
		draw_circle(p, TRIGGER_RADIUS, Color(color, 0.08))
		Draw2D.ring(self, p, TRIGGER_RADIUS, 0.12, Color(color, 0.7 + 0.2 * sin(time * 4.0)))
		Draw2D.ellipse(self, p, 1.1, Color(0, 0, 0, 0.35))
		var art: Array = ART[kind]
		if not _textures.has(kind):
			var path := "res://assets/sprites/decorado/%s.png" % art[0]
			_textures[kind] = load(path) if ResourceLoader.exists(path) else null
		if _textures[kind] != null:
			draw_circle(p + Vector2(0.0, -1.2), 1.6, Color(color, 0.08 + 0.04 * sin(time * 3.0)))
			Draw2D.sprite(self, _textures[kind], p + Vector2(0.0, 0.2), float(art[1]))
			continue
		var orb_y := -2.1 + 0.1 * sin(time * 3.0)
		match kind:
			Kind.MERCHANT:
				draw_rect(Rect2(p.x - 1.1, p.y - 1.2, 2.2, 1.2), Color(0.45, 0.3, 0.18))
				draw_rect(Rect2(p.x - 1.1, p.y - 1.2, 2.2, 1.2), Color(0.2, 0.12, 0.06), false, 0.08)
				draw_colored_polygon(PackedVector2Array([p + Vector2(-1.5, -1.1), p + Vector2(0.0, -2.8),
					p + Vector2(1.5, -1.1)]), color)
				draw_circle(p + Vector2(-0.7, 0.0), 0.3, Color(0.2, 0.12, 0.06))
				draw_circle(p + Vector2(0.7, 0.0), 0.3, Color(0.2, 0.12, 0.06))
			Kind.ALTAR:
				draw_rect(Rect2(p.x - 0.7, p.y - 1.4, 1.4, 1.4), stone)
				draw_rect(Rect2(p.x - 0.85, p.y - 1.55, 1.7, 0.3), stone.lightened(0.15))
				draw_circle(p + Vector2(0.0, orb_y), 0.75, Color(color, 0.2))
				draw_circle(p + Vector2(0.0, orb_y), 0.42, color)
			Kind.CONTRACT:
				draw_rect(Rect2(p.x - 0.5, p.y - 1.8, 1.0, 1.8), Color(0.4, 0.42, 0.48))
				draw_rect(Rect2(p.x - 0.5, p.y - 1.8, 1.0, 1.8), Color(0.15, 0.15, 0.2), false, 0.07)
				draw_circle(p + Vector2(0.0, orb_y - 0.3), 0.65, Color(color, 0.2))
				draw_circle(p + Vector2(0.0, orb_y - 0.3), 0.35, color)
