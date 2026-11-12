extends Weapon
## Guadaña Umbría (Sombra · Área): un tajo circular de sombra que remata
## siempre a los enemigos casi muertos.

const EXECUTE := 0.06
const TINT := Color(0.6, 0.35, 0.95)


func base_cooldown() -> float:
	return maxf(1.2, 2.2 - 0.1 * (level - 1))


func _fire() -> bool:
	var origin := champion.pos
	var radius := 3.6 * area()
	var targets := run.enemies_in_circle(origin, radius)
	if targets.is_empty():
		return false
	var amount := dmg(16.0 + 7.0 * (level - 1))
	for i: int in targets:
		run.hit_enemy(i, amount, source_id(), (run.swarm.pos[i] - origin).normalized() * 5.0, champion)
		run.execute_if_low(i, EXECUTE, source_id(), champion)
	run.vfx.disc(origin, radius, Color(TINT, 0.4), 0.2)
	return true
