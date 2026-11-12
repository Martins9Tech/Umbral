extends Weapon
## Arma de firma de Orrun: golpe en cono contra el enemigo más cercano; empuja.
## Evolución, Puño del Monte: onda en 360° mucho más grande y frecuente.

const CONE_COS := 0.5  # 60° a cada lado


func base_cooldown() -> float:
	if is_evolved():
		return 0.9
	return maxf(0.55, 1.1 - 0.07 * (level - 1))


func _fire() -> bool:
	var origin := champion.pos
	if is_evolved():
		var radius := 5.0 * area()
		if run.find_nearest_enemy(origin, radius) < 0:
			return false
		run.damage_circle(origin, radius, dmg(55.0), 13.0, source_id(), origin, champion)
		run.vfx.disc(origin, radius, Color(0.95, 0.6, 0.25, 0.45), 0.2)
		run.add_shake(0.08)
		champion.play_action(&"attack", 1.8)
		return true
	var reach := 3.2 * area()
	var target := run.find_nearest_enemy(origin, reach + 0.5)
	if target < 0:
		return false
	var direction := (run.swarm.pos[target] - origin).normalized()
	run.damage_cone(origin, direction, reach, CONE_COS, dmg(14.0 + 6.0 * (level - 1)), 9.0, source_id(), champion)
	run.vfx.disc(origin + direction * reach * 0.5, reach * 0.55, Color(0.95, 0.65, 0.3, 0.45), 0.15)
	champion.play_action(&"attack", 1.8)
	return true
