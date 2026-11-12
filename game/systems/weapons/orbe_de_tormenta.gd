extends Weapon
## Orbe de Tormenta (Rayo · Orbital): esferas eléctricas que orbitan lejos
## del campeón y electrocutan a los enemigos cercanos.

const ZAP_RANGE := 2.6
const ZAP_INTERVAL := 0.5
const TINT := Color(1.0, 0.92, 0.35)

var _angle := 0.0
var _zap_left := 0.0
var _orbs := PackedVector2Array()
var _time := 0.0


func _orb_count() -> int:
	return 1 + int(level >= 4) + int(level >= 7) + extra_amount()


func tick(delta: float) -> void:
	var n := _orb_count()
	_orbs.resize(n)
	_time += delta
	queue_redraw()

	_angle += delta * 1.3
	var orbit := 4.2 * area()
	var center := champion.pos
	_zap_left -= delta
	var do_zap := _zap_left <= 0.0
	if do_zap:
		_zap_left = ZAP_INTERVAL * champion.stats.get_stat(StatId.COOLDOWN)
	var amount := dmg(9.0 + 4.0 * (level - 1))
	var zaps := 1 + champion.chain_bonus()
	for k in n:
		var a := _angle + TAU * k / n
		var p := center + Vector2(cos(a), sin(a)) * orbit
		_orbs[k] = p
		if not do_zap:
			continue
		for target: int in run.find_nearest_enemies(p, ZAP_RANGE, zaps):
			run.vfx.line(p, run.swarm.pos[target], 0.2, Color(TINT, 0.9), 0.12)
			run.hit_enemy(target, amount, source_id(), Vector2.ZERO, champion)
			run.shock_enemy(target, champion)


## Esferas eléctricas flotando, con halo que chisporrotea.
func _draw() -> void:
	for k in _orbs.size():
		var p := _orbs[k] + Vector2(0.0, -1.2)
		draw_circle(p, 0.75 + 0.08 * sin(_time * 20.0 + k), Color(TINT, 0.22))
		draw_circle(p, 0.4, TINT)
		draw_circle(p, 0.2, Color(1, 1, 1, 0.9))
