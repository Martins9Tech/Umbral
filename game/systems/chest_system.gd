class_name ChestSystem
extends Node2D
## Cofres que sueltan las élites (GDD §5.4). Se abren al tocarlos; Run decide
## el contenido (evolución si hay alguna lista, si no mejoras).
## Dibujo 2D provisional (en metros) hasta tener su arte.

const PICKUP_RADIUS := 1.5
const BEAM_HEIGHT := 7.0
const GOLD := Color(0.95, 0.72, 0.2)

var _chests: Array[Dictionary] = []  # {pos, time}
var _texture: Texture2D = load("res://assets/sprites/decorado/cofre.png") \
	if ResourceLoader.exists("res://assets/sprites/decorado/cofre.png") else null


func count() -> int:
	return _chests.size()


func spawn(p: Vector2) -> void:
	_chests.append({"pos": p, "time": 0.0})


func positions() -> PackedVector2Array:
	var out := PackedVector2Array()
	for chest: Dictionary in _chests:
		out.append(chest["pos"])
	return out


## Posición del cofre más cercano dentro de max_dist, o Vector2.INF si no hay.
func nearest_position(p: Vector2, max_dist: float) -> Vector2:
	var best := Vector2.INF
	var best_sq := max_dist * max_dist
	for chest: Dictionary in _chests:
		var chest_pos: Vector2 = chest["pos"]
		var d2 := p.distance_squared_to(chest_pos)
		if d2 < best_sq:
			best_sq = d2
			best = chest_pos
	return best


## Anima los cofres y devuelve los jugadores que han abierto uno este frame.
func tick(delta: float, players: Array[Player]) -> Array[Player]:
	var opened: Array[Player] = []
	var pickup_sq := PICKUP_RADIUS * PICKUP_RADIUS
	queue_redraw()
	for k in range(_chests.size() - 1, -1, -1):
		var chest := _chests[k]
		var time: float = chest["time"]
		time += delta
		chest["time"] = time
		var p: Vector2 = chest["pos"]
		for player: Player in players:
			if player.is_dead() or player.pos.distance_squared_to(p) > pickup_sq:
				continue
			opened.append(player)
			_chests.remove_at(k)
			break
	return opened


## Cofre dorado que flota, con un haz de luz alto para verlo desde lejos.
func _draw() -> void:
	for chest: Dictionary in _chests:
		var p: Vector2 = chest["pos"]
		var time: float = chest["time"]
		var lift := 0.15 + 0.12 * sin(time * 3.0)
		Draw2D.ellipse(self, p, 0.8, Color(0, 0, 0, 0.35))
		draw_rect(Rect2(p.x - 0.3, p.y - BEAM_HEIGHT, 0.6, BEAM_HEIGHT), Color(1.0, 0.85, 0.35, 0.14))
		if _texture != null:
			draw_circle(p + Vector2(0.0, -0.6 - lift), 1.1, Color(1.0, 0.8, 0.3, 0.12 + 0.06 * sin(time * 4.0)))
			Draw2D.sprite(self, _texture, p + Vector2(0.0, -lift), 1.4)
			continue
		var body := Rect2(p.x - 0.55, p.y - 0.75 - lift, 1.1, 0.7)
		draw_rect(body, GOLD)
		draw_rect(body, GOLD.darkened(0.6), false, 0.06)
		var lid := Rect2(p.x - 0.62, p.y - 1.0 - lift, 1.24, 0.3)
		draw_rect(lid, GOLD.lightened(0.25))
		draw_rect(lid, GOLD.darkened(0.6), false, 0.06)
		draw_circle(Vector2(p.x, p.y - 0.62 - lift), 0.1, Color(0.35, 0.2, 0.05))
