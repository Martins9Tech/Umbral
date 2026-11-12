extends Weapon
## Mortero Alquímico (Fuego · Área): lanza proyectiles en arco a enemigos
## cercanos; al caer explotan y dejan a los enemigos ardiendo.

const RANGE := 14.0
const FLIGHT_TIME := 0.6
const BURN_TIME := 3.0
const TINT := Color(1.0, 0.5, 0.15)

var _shells: Array[Dictionary] = []  # {pos, time}


func base_cooldown() -> float:
	return maxf(1.2, 2.2 - 0.12 * (level - 1))


func _radius() -> float:
	return 2.4 * area()


func _fire() -> bool:
	var origin := champion.pos
	var shots := 1 + int(level / 3.0) + extra_amount()
	var candidates := run.find_nearest_enemies(origin, RANGE, shots * 4)
	if candidates.is_empty():
		return false
	for k in shots:
		var target := candidates[randi() % candidates.size()]
		var p := run.swarm.pos[target]
		# Aviso del impacto (efecto del jugador, no telegrafía enemiga).
		run.vfx.disc(p, _radius(), Color(TINT, 0.18), FLIGHT_TIME)
		_shells.append({"pos": p, "time": FLIGHT_TIME})
	return true


func tick(delta: float) -> void:
	super(delta)
	for k in range(_shells.size() - 1, -1, -1):
		var shell := _shells[k]
		var time_left: float = shell["time"]
		time_left -= delta
		shell["time"] = time_left
		if time_left > 0.0:
			continue
		var p: Vector2 = shell["pos"]
		var radius := _radius()
		var amount := dmg(14.0 + 6.0 * (level - 1))
		for i: int in run.enemies_in_circle(p, radius):
			run.hit_enemy(i, amount, source_id(), (run.swarm.pos[i] - p).normalized() * 4.0, champion)
			run.burn_enemy(i, 6.0 + 2.0 * level, BURN_TIME, champion)
		run.vfx.disc(p, radius, Color(TINT, 0.55), 0.25)
		_shells.remove_at(k)
