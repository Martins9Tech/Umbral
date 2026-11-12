extends Weapon
## Minas de Brea (Fuego · Trampa): deja minas a tu paso que explotan al
## acercarse un enemigo y lo dejan ardiendo.

const ARM_TIME := 0.5
const TRIGGER_RADIUS := 1.3
const BURN_TIME := 4.0
const TINT := Color(1.0, 0.42, 0.12)

var _mines: Array[Dictionary] = []  # {pos, time}


func base_cooldown() -> float:
	return maxf(0.7, 1.4 - 0.06 * (level - 1))


func _max_mines() -> int:
	return 3 + int(level / 2.0) + extra_amount()


func _fire() -> bool:
	if _mines.size() >= _max_mines():
		return false
	_mines.append({"pos": champion.pos, "time": 0.0})
	return true


func tick(delta: float) -> void:
	super(delta)
	queue_redraw()
	for k in range(_mines.size() - 1, -1, -1):
		var mine := _mines[k]
		var time: float = mine["time"]
		time += delta
		mine["time"] = time
		if time < ARM_TIME:
			continue
		var p: Vector2 = mine["pos"]
		if run.find_nearest_enemy(p, TRIGGER_RADIUS) < 0:
			continue
		var radius := 2.8 * area()
		var amount := dmg(22.0 + 8.0 * (level - 1))
		for i: int in run.enemies_in_circle(p, radius):
			run.hit_enemy(i, amount, source_id(), (run.swarm.pos[i] - p).normalized() * 7.0, champion)
			run.burn_enemy(i, 8.0 + 2.0 * level, BURN_TIME, champion)
		run.vfx.disc(p, radius, Color(TINT, 0.6), 0.3)
		_mines.remove_at(k)


## Charcos de brea con un brillo de fuego que parpadea al armarse.
func _draw() -> void:
	for mine: Dictionary in _mines:
		var p: Vector2 = mine["pos"]
		var armed := float(mine["time"]) >= ARM_TIME
		Draw2D.ellipse(self, p, 0.5, Color(0.1, 0.08, 0.08), 0.6)
		var glow := 0.6 + 0.4 * sin(float(mine["time"]) * 8.0) if armed else 0.25
		Draw2D.ellipse(self, p, 0.28, Color(TINT, glow), 0.6)
