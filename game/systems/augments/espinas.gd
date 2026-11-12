extends Augment
## Espinas: al recibir daño, devuelve el triple a los enemigos cercanos.

const RADIUS := 3.0
const REFLECT := 3.0

var _cooldown := 0.0


func tick(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)


func on_damaged(amount: float) -> void:
	if _cooldown > 0.0:
		return
	_cooldown = 0.25  # agrupa el daño continuo de contacto
	var reflected := maxf(amount * REFLECT, 15.0) * player.stats.get_stat(StatId.DAMAGE)
	run.damage_circle(player.pos, RADIUS, reflected, 8.0, &"espinas", player.pos, player)
	run.vfx.disc(player.pos, RADIUS, Color(0.55, 0.85, 0.3, 0.4), 0.2)
