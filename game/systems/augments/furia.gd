extends Augment
## Furia: tras usar la Definitiva, +50 % de daño durante 12 s.

const DURATION := 12.0
const BONUS := 0.5
const SOURCE := &"furia_activa"

var _left := 0.0


func on_ability_cast(ability_id: StringName) -> void:
	if ability_id != player.kit.ultimate_id:
		return
	if _left <= 0.0:
		player.stats.add_modifier(StatId.DAMAGE, Stats.Kind.PERCENT, BONUS, SOURCE)
	_left = DURATION
	run.notify_augment("¡Furia! +50 % de daño durante 12 s.")


func tick(delta: float) -> void:
	if _left <= 0.0:
		return
	_left -= delta
	if _left <= 0.0:
		player.stats.remove_source(SOURCE)
