extends Augment
## Vampirismo: el 3 % del daño que haces te cura (máx. 8 por segundo).

const RATIO := 0.03
const MAX_PER_SECOND := 8.0

var _budget := MAX_PER_SECOND


func tick(delta: float) -> void:
	_budget = minf(MAX_PER_SECOND, _budget + MAX_PER_SECOND * delta)


func on_hit(amount: float, _was_crit: bool) -> void:
	var heal := minf(amount * RATIO, _budget)
	if heal > 0.0:
		_budget -= heal
		player.heal(heal)
