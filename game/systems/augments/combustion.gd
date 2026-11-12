extends Augment
## Combustión: los enemigos que matas tienen un 20 % de probabilidad de
## explotar y dañar a los de alrededor.

const CHANCE := 0.2
const RADIUS := 3.0
const DAMAGE := 30.0


func on_kill(p: Vector2, _flags: int) -> void:
	if run.rng_loot.randf() >= CHANCE:
		return
	var amount := DAMAGE * player.stats.get_stat(StatId.DAMAGE)
	# Se aplaza: ahora mismo se están retirando los muertos del frame.
	run.queue_blast(p, RADIUS * player.stats.get_stat(StatId.AREA), amount, &"combustion", player)
