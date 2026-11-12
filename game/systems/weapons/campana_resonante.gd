extends Weapon
## Campana Resonante: onda expansiva periódica alrededor del campeón; empuja.
## Evolución, Campana del Juicio: onda enorme cuyo daño escala con la vida máxima.


func base_cooldown() -> float:
	if is_evolved():
		return 1.5
	return maxf(1.6, 3.0 - 0.18 * (level - 1))


func _fire() -> bool:
	var origin := champion.pos
	if is_evolved():
		var big_radius := 7.0 * area()
		var amount := dmg(40.0 + 0.25 * champion.max_hp())
		run.damage_circle(origin, big_radius, amount, 16.0, source_id(), origin, champion)
		run.vfx.disc(origin, big_radius, Color(1.0, 0.8, 0.3, 0.4), 0.3)
		return true
	var radius := (4.0 + 0.35 * (level - 1)) * area()
	run.damage_circle(origin, radius, dmg(10.0 + 5.0 * (level - 1)), 12.0, source_id(), origin, champion)
	run.vfx.disc(origin, radius, Color(1.0, 0.9, 0.5, 0.35), 0.25)
	return true
