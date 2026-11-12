extends Augment
## Sed de Batalla: cada muerte cura 0,6 de vida (máx. 6 por segundo).

const HEAL_PER_KILL := 0.6
const MAX_PER_SECOND := 6.0

var _budget := MAX_PER_SECOND


func tick(delta: float) -> void:
	_budget = minf(MAX_PER_SECOND, _budget + MAX_PER_SECOND * delta)


func on_kill(_p: Vector2, _flags: int) -> void:
	if _budget >= HEAL_PER_KILL:
		_budget -= HEAL_PER_KILL
		player.heal(HEAL_PER_KILL)
