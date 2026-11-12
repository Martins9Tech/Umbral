extends Weapon
## Cuchillas Orbitales: giran alrededor del campeón y dañan lo que tocan.
## Evolución, Danza de Mil Filos: 8 cuchillas doradas, órbita mayor y más rápida.

const BLADE_HIT_RADIUS := 0.75

var _angle := 0.0
var _hit_left := 0.0
var _blades := PackedVector2Array()
var _blade_angles := PackedFloat32Array()


func _blade_count() -> int:
	if is_evolved():
		return 8 + extra_amount()
	return 1 + int(level >= 3) + int(level >= 5) + int(level >= 7) + extra_amount()


func tick(delta: float) -> void:
	var n := _blade_count()
	_blades.resize(n)
	_blade_angles.resize(n)
	queue_redraw()

	var evolved := is_evolved()
	_angle += delta * (4.2 if evolved else 2.6 + 0.15 * level)
	var orbit := (3.4 if evolved else 2.6) * area()
	var center := champion.pos
	_hit_left -= delta
	var do_hit := _hit_left <= 0.0
	if do_hit:
		_hit_left = 0.2 if evolved else 0.3
	var amount := dmg(32.0 if evolved else 7.0 + 3.0 * (level - 1))
	for k in n:
		var a := _angle + TAU * k / n
		var p := center + Vector2(cos(a), sin(a)) * orbit
		_blades[k] = p
		_blade_angles[k] = a
		if do_hit:
			run.damage_circle(p, BLADE_HIT_RADIUS * area(), amount, 3.0, source_id(), center, champion)


## Hojas de metal que giran (doradas al evolucionar), a media altura.
func _draw() -> void:
	var evolved := is_evolved()
	var length := 1.4 if evolved else 1.0
	var color := Color(1.0, 0.82, 0.35) if evolved else Color(0.85, 0.88, 0.95)
	for k in _blades.size():
		var p := _blades[k] + Vector2(0.0, -0.8)
		var dir := Vector2.from_angle(_blade_angles[k] + PI * 0.5)
		var side := dir.orthogonal() * 0.16
		var tip := p + dir * length * 0.5
		var back := p - dir * length * 0.5
		var shape := PackedVector2Array([tip, p + side, back, p - side])
		draw_colored_polygon(shape, color)
		draw_polyline(shape + PackedVector2Array([tip]), color.darkened(0.6), 0.05)
