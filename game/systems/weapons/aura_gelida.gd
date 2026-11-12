extends Weapon
## Aura Gélida (Hielo · Área): un aura constante a tu alrededor que daña y
## ralentiza a quien entra.

const TICK := 0.5
const SLOW_TIME := 1.0

var _tick_left := 0.0
var _center := Vector2.ZERO
var _time := 0.0


func _radius() -> float:
	return (2.8 + 0.25 * (level - 1)) * area()


func tick(delta: float) -> void:
	var radius := _radius()
	var center := champion.pos
	_center = center
	_time += delta
	queue_redraw()
	_tick_left -= delta
	if _tick_left > 0.0:
		return
	_tick_left = TICK * champion.stats.get_stat(StatId.COOLDOWN)
	var amount := dmg(4.0 + 2.0 * (level - 1))
	for i: int in run.enemies_in_circle(center, radius):
		run.hit_enemy(i, amount, source_id(), Vector2.ZERO, champion)
		run.chill_enemy(i, SLOW_TIME, champion)


## Disco helado con borde que respira.
func _draw() -> void:
	var radius := _radius()
	draw_circle(_center, radius, Color(0.55, 0.85, 1.0, 0.14))
	Draw2D.ring(self, _center, radius, 0.1, Color(0.7, 0.92, 1.0, 0.45 + 0.15 * sin(_time * 3.0)))
