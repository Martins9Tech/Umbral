extends Weapon
## Cadena de Escarcha (Hielo · Proyectil): un rayo de hielo que salta entre
## varios enemigos y los ralentiza.

const FIRST_RANGE := 12.0
const JUMP_RANGE := 6.0
const SLOW_TIME := 2.0
const TINT := Color(0.55, 0.85, 1.0)


func base_cooldown() -> float:
	return maxf(0.8, 1.5 - 0.07 * (level - 1))


func _fire() -> bool:
	var current := run.find_nearest_enemy(champion.pos, FIRST_RANGE)
	if current < 0:
		return false
	var jumps := 3 + int(level / 2.0) + extra_amount()
	var amount := dmg(12.0 + 5.0 * (level - 1))
	var hit: Dictionary = {}
	var from := champion.pos
	for _k in jumps:
		var p := run.swarm.pos[current]
		run.vfx.line(from, p, 0.3, Color(TINT, 0.85), 0.18)
		run.hit_enemy(current, amount, source_id(), Vector2.ZERO, champion)
		run.chill_enemy(current, SLOW_TIME, champion)
		hit[current] = true
		from = p
		current = -1
		for candidate: int in run.find_nearest_enemies(p, JUMP_RANGE, 6):
			if not hit.has(candidate):
				current = candidate
				break
		if current < 0:
			break
	return true
