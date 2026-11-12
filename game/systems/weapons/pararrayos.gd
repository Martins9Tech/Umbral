extends Weapon
## Pararrayos (Rayo · Área): rayos del cielo sobre enemigos cercanos que
## saltan a otro enemigo próximo.

const RANGE := 14.0
const CHAIN_RANGE := 4.0
const TINT := Color(1.0, 0.92, 0.35)


func base_cooldown() -> float:
	return maxf(0.8, 1.6 - 0.08 * (level - 1))


func _fire() -> bool:
	var candidates := run.find_nearest_enemies(champion.pos, RANGE, 20)
	if candidates.is_empty():
		return false
	var strikes := 1 + int(level / 2.0) + extra_amount()
	var amount := dmg(20.0 + 8.0 * (level - 1))
	var chains := 1 + champion.chain_bonus()
	for _k in strikes:
		var target := candidates[randi() % candidates.size()]
		if not run.is_valid_target(target):
			continue
		var p := run.swarm.pos[target]
		run.vfx.bolt(p, Color(TINT, 0.9), 0.15)
		_zap(target, amount)
		# Salta a los más cercanos con menos daño.
		var from := p
		var hit := {target: true}
		for _c in chains:
			var next := -1
			for candidate: int in run.find_nearest_enemies(from, CHAIN_RANGE, 5):
				if not hit.has(candidate):
					next = candidate
					break
			if next < 0:
				break
			var next_pos := run.swarm.pos[next]
			run.vfx.line(from, next_pos, 0.25, Color(TINT, 0.85), 0.15)
			_zap(next, amount * 0.6)
			hit[next] = true
			from = next_pos
	return true


func _zap(i: int, amount: float) -> void:
	run.hit_enemy(i, amount, source_id(), Vector2.ZERO, champion)
	run.shock_enemy(i, champion)
