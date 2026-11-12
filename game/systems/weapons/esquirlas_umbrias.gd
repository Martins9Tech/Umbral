extends Weapon
## Esquirlas Umbrías: proyectiles hacia los enemigos más cercanos.
## Evolución, Tormenta Umbría: el doble de esquirlas, más rápidas y perforantes.

const RANGE := 18.0
const SPEED := 17.0
const LIFETIME := 1.6
const TINT := Color(0.62, 0.38, 1.0)
const EVOLVED_TINT := Color(0.85, 0.45, 1.0)


func base_cooldown() -> float:
	if is_evolved():
		return 0.5
	return maxf(0.6, 1.3 - 0.06 * (level - 1))


func _fire() -> bool:
	var evolved := is_evolved()
	var shots := (8 if evolved else 1 + int(level * 0.5)) + extra_amount()
	var origin := champion.pos
	var targets := run.find_nearest_enemies(origin, RANGE, shots)
	if targets.is_empty():
		return false
	var pierce := 3 if evolved else int(level >= 4) + int(level >= 8)
	var amount := dmg(25.0 if evolved else 9.0 + 4.0 * (level - 1))
	var radius := (0.36 if evolved else 0.28) * sqrt(area())
	var speed := SPEED * (1.3 if evolved else 1.0)
	for k in shots:
		var target := targets[k % targets.size()]
		var direction := (run.swarm.pos[target] - origin).normalized()
		if k >= targets.size():
			direction = direction.rotated(randf_range(-0.35, 0.35))
		run.projectiles.spawn(origin, direction * speed, amount, radius, LIFETIME, pierce,
			source_id(), EVOLVED_TINT if evolved else TINT, champion.player_index)
	return true
