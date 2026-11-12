extends Augment
## Ímpetu Eterno: la Definitiva se carga sola con el tiempo y no se bloquea
## tras usarla.

const IMPETU_PER_SECOND := 4.0


func tick(delta: float) -> void:
	var kit := player.kit
	kit.impetu_lockout_left = 0.0
	if not kit.ultimate_active():
		kit.impetu = minf(ChampionKit.IMPETU_MAX, kit.impetu + IMPETU_PER_SECOND * delta)
