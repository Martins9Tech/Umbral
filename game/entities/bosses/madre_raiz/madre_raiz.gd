class_name BossMadreRaiz
extends Boss
## La Madre Raíz, jefa del Bosque de los Susurros (GDD §7.2).
## Fase 1 (100-70 %): arraigada. Raíces bajo los jugadores, barrido de ramas
##   en cono y hojas en espiral.
## Fase 2 (70-40 %): las zarzas cierran la arena; invoca Brotes que la curan
##   si no mueren en 10 s; raíces en líneas cruzadas.
## Fase 3 (40-0 %): se arranca del suelo, persigue, deja rastro de espinas y
##   embiste en línea.
## Último aliento (10 %): lluvia de semillas en toda la arena salvo zonas seguras.

const ARENA_START := 22.0
const ARENA_PHASE2 := 16.0
const ROOT_RADIUS := 2.4
const ROOT_DAMAGE := 26.0
const SWEEP_RADIUS := 10.0
const SWEEP_HALF_ANGLE := 0.95
const SWEEP_DAMAGE := 32.0
const LEAF_DAMAGE := 12.0
const LEAF_SPEED := 9.0
const LINE_DAMAGE := 28.0
const SPROUT_TIME := 10.0
const SPROUT_HEAL := 0.04
const SPROUTS_PER_WAVE := 4
const CHASE_SPEED := 2.8
const CHARGE_LENGTH := 15.0
const CHARGE_DAMAGE := 36.0
const TRAIL_INTERVAL := 0.9
const TRAIL_DPS := 14.0
const LAST_BREATH_DAMAGE := 75.0

var _rng := RandomNumberGenerator.new()
var _attack_left := 3.0
var _pattern_index := 0
var _spiral_left := 0
var _spiral_timer := 0.0
var _spiral_angle := 0.0
var _trail_left := 0.0
var _charge: Dictionary = {}
var _last_breath_done := false
var _uprooted := false
var _hop_time := 0.0
var _canopy_alpha := 1.0

## Su dibujo (con raíces dibujadas en el suelo en las fases 1 y 2).
const BODY_TEXTURE := preload("res://assets/sprites/decorado/madre_raiz.png")
const BODY_HEIGHT := 7.5
const CANOPY_COLOR := Color(0.24, 0.46, 0.2)
const ROOT_COLOR := Color(0.36, 0.24, 0.15)

var _body: Sprite2D
var _show_roots := true
var _flashing := false


func _on_setup() -> void:
	display_name = "La Madre Raíz"
	max_hp = 28000.0
	arena_radius = ARENA_START
	phase_thresholds = [0.7, 0.4]
	_rng.seed = run.run_seed + 7


func _body_radius() -> float:
	return 2.6


func _contact_dps() -> float:
	return 35.0


func _build_visual() -> void:
	_body = Sprite2D.new()
	_body.texture = BODY_TEXTURE
	_body.centered = false
	var size := BODY_TEXTURE.get_size()
	_body.offset = -Vector2(0.5 * size.x, 0.96 * size.y)
	_body.scale = Vector2.ONE * BODY_HEIGHT / (0.96 * size.y)
	add_child(_body)


func _update_visual(delta: float, flashing: bool) -> void:
	_flashing = flashing
	var tint := Color.WHITE
	if enraged:
		tint = Color(1.0, 0.6, 0.5)
	_body.modulate = Color(2.0, 2.0, 2.0) if flashing else tint
	var near := nearest_player().pos.distance_to(pos2d())
	# La copa se vuelve transparente cerca, para no tapar los avisos del suelo.
	_canopy_alpha = lerpf(_canopy_alpha, 0.55 if near < 5.0 else 1.0, 1.0 - exp(-8.0 * delta))
	_body.modulate.a = _canopy_alpha
	if _uprooted:
		# Avanza a saltitos.
		_hop_time += delta
		_body.position.y = -absf(sin(_hop_time * 5.0)) * 0.5
		_body.rotation = sin(_hop_time * 5.0) * 0.06
	else:
		_body.position.y = 0.0
	_body.flip_h = nearest_player().pos.x < pos2d().x
	queue_redraw()


## Sombra, raíces (fases 1-2) y copa por detrás del tronco.
func _draw() -> void:
	if not _body.visible:
		return
	Draw2D.ellipse(self, Vector2.ZERO, 3.2, Color(0, 0, 0, 0.45))
	if _show_roots:
		for k in 6:
			var dir := Vector2.from_angle(TAU * k / 6.0 + 0.3)
			Draw2D.band(self, dir * 1.2, dir * 4.2, 0.55, ROOT_COLOR)
	# Brillo verde bajo la jefa.
	Draw2D.ellipse(self, Vector2.ZERO, 3.8, Color(0.4, 1.0, 0.35, 0.08 + 0.04 * sin(_hop_time * 3.0 + Time.get_ticks_msec() * 0.002)))


func _on_phase_start(new_phase: int) -> void:
	_charge = {}
	_spiral_left = 0
	_attack_left = TRANSITION_TIME + 1.0
	match new_phase:
		2:
			run.notify_boss("¡La Madre Raíz grita! Las zarzas cierran la arena: no salgas del círculo.")
			set_arena_radius(ARENA_PHASE2)
			_spawn_sprouts()
		3:
			run.notify_boss("¡La Madre Raíz se arranca del suelo y te persigue! Esquiva sus embestidas.")
			_uprooted = true
			_show_roots = false
	run.add_shake(0.5)


func _tick_fight(delta: float) -> void:
	_tick_spiral(delta)
	_tick_sprouts()
	if phase >= 3:
		_tick_chase(delta)
		if not _last_breath_done and hp_fraction() <= 0.1:
			_last_breath()
	_attack_left -= delta
	if _attack_left > 0.0 or not _charge.is_empty():
		return
	var patterns: Array[Callable] = []
	match phase:
		1:
			_attack_left = 2.8
			patterns = [_attack_roots, _attack_sweep, _attack_spiral]
		2:
			_attack_left = 2.4
			patterns = [_attack_cross_lines, _attack_roots, _attack_sweep, _spawn_sprouts]
		_:
			_attack_left = 2.1
			patterns = [_attack_charge, _attack_roots, _attack_spiral]
	patterns[_pattern_index % patterns.size()].call()
	_pattern_index += 1


# --- Patrones ---

## Raíces: círculos bajo cada jugador y alrededor.
func _attack_roots() -> void:
	for champion: Player in run.alive_players():
		run.telegraphs.circle(champion.pos, ROOT_RADIUS, 1.2, ROOT_DAMAGE)
		for _k in 2:
			var offset := Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(3.0, 6.0)
			run.telegraphs.circle(champion.pos + offset, ROOT_RADIUS, 1.4, ROOT_DAMAGE)


## Barrido de ramas: cono hacia el jugador más cercano.
func _attack_sweep() -> void:
	var target := nearest_player()
	var direction := (target.pos - pos2d()).normalized()
	run.telegraphs.cone(pos2d(), direction, SWEEP_RADIUS, SWEEP_HALF_ANGLE, 1.1, SWEEP_DAMAGE)


## Hojas cortantes en espiral (proyectiles).
func _attack_spiral() -> void:
	_spiral_left = 36
	_spiral_timer = 0.0
	_spiral_angle = _rng.randf() * TAU


func _tick_spiral(delta: float) -> void:
	if _spiral_left <= 0:
		return
	_spiral_timer -= delta
	while _spiral_timer <= 0.0 and _spiral_left > 0:
		_spiral_timer += 0.05
		_spiral_left -= 1
		for arm in 3:
			var angle := _spiral_angle + TAU * arm / 3.0
			fire_projectile(pos2d(), Vector2.from_angle(angle) * LEAF_SPEED, LEAF_DAMAGE)
		_spiral_angle += 0.22


## Raíces en líneas cruzadas que pasan por el jugador.
func _attack_cross_lines() -> void:
	var target := nearest_player().pos
	var base_angle := _rng.randf() * PI
	for k in 2:
		var direction := Vector2.from_angle(base_angle + PI * 0.5 * k)
		run.telegraphs.line(target - direction * 16.0, target + direction * 16.0, 2.2, 1.3, LINE_DAMAGE)


## Brotes: si no mueren en 10 s, curan a la jefa.
func _spawn_sprouts() -> void:
	var hp := 100.0 * run.swarm.hp_scale
	for _k in SPROUTS_PER_WAVE:
		var p := pos2d() + Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(5.0, 9.0)
		run.swarm.spawn(0, p, EnemySwarm.FLAG_SPROUT, hp, 0.75, 10.0, SPROUT_TIME)
	run.notify_boss("¡Brotes! Mátalos antes de 10 s o curarán a la Madre Raíz.")


func _tick_sprouts() -> void:
	var swarm := run.swarm
	for i in swarm.count:
		if swarm.flags[i] & EnemySwarm.FLAG_SPROUT and swarm.hp[i] > 0.0 and swarm.timer[i] <= 0.0:
			heal_fraction(SPROUT_HEAL)
			run.vfx.line(swarm.pos[i], pos2d(), 0.6, Color(0.4, 1.0, 0.35, 0.7), 0.6)
			swarm.kill_silent(i)


## Fase 3: persigue al jugador más cercano dejando un rastro de espinas.
func _tick_chase(delta: float) -> void:
	if not _charge.is_empty():
		_tick_charge(delta)
		return
	var target := nearest_player().pos
	var p := pos2d()
	var to_target := target - p
	if to_target.length() > 3.0:
		p += to_target.normalized() * CHASE_SPEED * delta
		set_pos2d(_clamp_to_arena(p))
	_trail_left -= delta
	if _trail_left <= 0.0:
		_trail_left = TRAIL_INTERVAL
		run.telegraphs.circle(pos2d(), 1.6, 0.4, 0.0, 5.0, TRAIL_DPS)


## Embestida: aviso en línea y luego avanza por ella.
func _attack_charge() -> void:
	var start := pos2d()
	var direction := (nearest_player().pos - start).normalized()
	var end := _clamp_to_arena(start + direction * CHARGE_LENGTH)
	run.telegraphs.line(start, end, 3.2, 1.0, CHARGE_DAMAGE)
	_charge = {"from": start, "to": end, "time": 0.0}


func _tick_charge(delta: float) -> void:
	var time: float = _charge["time"]
	time += delta
	_charge["time"] = time
	if time < 1.0:
		return  # esperando al aviso
	var t := clampf((time - 1.0) / 0.35, 0.0, 1.0)
	var from: Vector2 = _charge["from"]
	var to: Vector2 = _charge["to"]
	set_pos2d(from.lerp(to, t))
	if t >= 1.0:
		_charge = {}
		run.add_shake(0.3)


## Último aliento: toda la arena salvo tres zonas seguras.
func _last_breath() -> void:
	_last_breath_done = true
	var safes := PackedVector2Array()
	for k in 3:
		var p := arena_center + Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(3.0, arena_radius - 4.0)
		safes.append(p)
	run.telegraphs.safe_zones(arena_center, arena_radius + 2.0, safes, 3.0, 3.2, LAST_BREATH_DAMAGE)
	run.notify_boss("¡ÚLTIMO ALIENTO! Corre a una zona VERDE antes de que caigan las semillas.")
	_attack_left = 4.0


func _on_defeated() -> void:
	run.telegraphs.clear()
	run.vfx.disc(pos2d(), 8.0, Color(0.5, 1.0, 0.4, 0.6), 1.2)
	_body.visible = false
	queue_redraw()
	hide_arena()


func _clamp_to_arena(p: Vector2) -> Vector2:
	var offset := p - arena_center
	var max_dist := arena_radius - 2.0
	if offset.length() > max_dist:
		p = arena_center + offset.normalized() * max_dist
	return p
