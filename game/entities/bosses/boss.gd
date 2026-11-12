class_name Boss
extends Node2D
## Base de los jefes (GDD §7): vida en la horda (así todas las armas le
## afectan), fases por umbral de vida con transición invulnerable, arena con
## borde de zarzas, proyectiles enemigos, furia si el combate se alarga y
## ataques telegrafiados. Cada jefe concreto implementa sus patrones.
## Dibujo 2D en metros: el nodo está a los pies del jefe; la arena se dibuja
## en la capa del suelo y los proyectiles en la capa aérea de Run.

signal phase_changed(phase: int)

const RISE_TIME := 2.5
const TRANSITION_TIME := 2.0
const ENRAGE_TIME := 240.0
const ENRAGE_SPEED := 1.55
const THORN_DPS := 22.0
const MAX_PROJECTILES := 400
const PROJECTILE_HIT_RADIUS := 0.55
## Transformación 2D (8).
const FLOATS_PER_INSTANCE := 8
const THORN_COLOR := Color(0.22, 0.3, 0.12)
const LEAF_COLOR := Color(0.75, 1.0, 0.3)

var run: Run
var display_name := "Jefe"
var max_hp := 10000.0
## Umbrales de vida (fracción) en los que empieza cada fase siguiente.
var phase_thresholds: Array[float] = [0.7, 0.4]
var phase := 1
var arena_center := Vector2.ZERO
var arena_radius := 22.0
var enraged := false

var _state := &"rising"  # rising, fighting, transition, dead
var _state_time := 0.0
var _fight_time := 0.0
var _arena_node: Node2D
var _arena_visible := true

# Proyectiles enemigos (hojas, semillas...)
var _proj_count := 0
var _proj_pos := PackedVector2Array()
var _proj_vel := PackedVector2Array()
var _proj_life := PackedFloat32Array()
var _proj_damage := PackedFloat32Array()
var _proj_multimesh: MultiMesh
var _proj_buffer := PackedFloat32Array()


func setup(p_run: Run, p_center: Vector2, p_arena_center: Vector2) -> void:
	run = p_run
	arena_center = p_arena_center
	_on_setup()
	var scaled_hp := max_hp * (1.0 + 0.6 * (run.players.size() - 1))
	run.swarm.spawn(0, p_center, EnemySwarm.FLAG_BOSS, scaled_hp, _body_radius(), _contact_dps())
	run.swarm.damage_mult[run.swarm.boss_slot] = 0.0  # invulnerable mientras emerge
	position = p_center
	_build_arena()
	_build_projectiles()
	_build_visual()


# --- Para sobrescribir ---

func _on_setup() -> void:
	pass


func _body_radius() -> float:
	return 2.5


func _contact_dps() -> float:
	return 30.0


func _build_visual() -> void:
	pass


## Patrones de ataque de la fase actual.
func _tick_fight(_delta: float) -> void:
	pass


## Se llama al empezar cada fase (2, 3...).
func _on_phase_start(_new_phase: int) -> void:
	pass


## Se llama cada frame con el estado visual (destello al recibir daño, etc.).
func _update_visual(_delta: float, _flashing: bool) -> void:
	pass


func _on_defeated() -> void:
	pass


# --- Estado ---

func slot() -> int:
	return run.swarm.boss_slot


func is_alive() -> bool:
	return slot() >= 0 and _state != &"dead"


func hp_fraction() -> float:
	var i := slot()
	if i < 0:
		return 0.0
	return clampf(run.swarm.hp[i] / run.swarm.max_hp[i], 0.0, 1.0)


func pos2d() -> Vector2:
	var i := slot()
	return run.swarm.pos[i] if i >= 0 else position


func set_pos2d(p: Vector2) -> void:
	var i := slot()
	if i >= 0:
		run.swarm.pos[i] = p
	position = p


func heal_fraction(fraction: float) -> void:
	var i := slot()
	if i >= 0:
		run.swarm.hp[i] = minf(run.swarm.max_hp[i], run.swarm.hp[i] + run.swarm.max_hp[i] * fraction)


func state_name() -> StringName:
	return _state


# --- Bucle ---

func tick(delta: float) -> void:
	if _state == &"dead":
		return
	var i := slot()
	if i < 0:
		return
	_state_time += delta
	match _state:
		&"rising":
			scale = Vector2.ONE * lerpf(0.3, 1.0, clampf(_state_time / RISE_TIME, 0.0, 1.0))
			if _state_time >= RISE_TIME:
				_set_state(&"fighting")
				run.swarm.damage_mult[i] = 1.0
		&"transition":
			if _state_time >= TRANSITION_TIME:
				_set_state(&"fighting")
				run.swarm.damage_mult[i] = 1.0
		&"fighting":
			_fight_time += delta
			if not enraged and _fight_time >= ENRAGE_TIME:
				enraged = true
				run.notify_boss("¡%s se enfurece! Ataca más rápido." % display_name)
			if phase - 1 < phase_thresholds.size() and hp_fraction() <= phase_thresholds[phase - 1]:
				_begin_phase(phase + 1)
			else:
				_tick_fight(delta * (ENRAGE_SPEED if enraged else 1.0))
	position = pos2d()
	_tick_arena(delta)
	_tick_projectiles(delta)
	_arena_node.queue_redraw()
	_update_visual(delta, run.swarm.flash[i] > 0.0)


func defeat() -> void:
	_set_state(&"dead")
	_proj_count = 0
	_render_projectiles()
	_on_defeated()


func _begin_phase(new_phase: int) -> void:
	phase = new_phase
	_set_state(&"transition")
	run.swarm.damage_mult[slot()] = 0.0
	_on_phase_start(new_phase)
	phase_changed.emit(new_phase)


func _set_state(new_state: StringName) -> void:
	_state = new_state
	_state_time = 0.0


# --- Arena ---

func set_arena_radius(radius: float) -> void:
	arena_radius = radius
	if _arena_node != null:
		_arena_node.queue_redraw()


func hide_arena() -> void:
	_arena_visible = false
	_arena_node.queue_redraw()


func _build_arena() -> void:
	_arena_node = Node2D.new()
	_arena_node.name = "BossArena"
	_arena_node.draw.connect(_draw_arena)
	run.ground_fx.add_child(_arena_node)


## Borde de zarzas: anillo oscuro con espinas hacia dentro.
func _draw_arena() -> void:
	if not _arena_visible:
		return
	var c := arena_center
	_arena_node.draw_arc(c, arena_radius + 0.7, 0.0, TAU, 96, Color(THORN_COLOR, 0.95), 1.4)
	_arena_node.draw_arc(c, arena_radius, 0.0, TAU, 96, Color(0.55, 0.15, 0.1, 0.6), 0.12)
	var spikes := int(arena_radius * 3.0)
	for k in spikes:
		var angle := TAU * k / spikes
		var dir := Vector2.from_angle(angle)
		var base := c + dir * (arena_radius + 0.1)
		var side := dir.orthogonal() * 0.25
		_arena_node.draw_colored_polygon(PackedVector2Array([base + side, base - side,
			c + dir * (arena_radius - 0.7)]), THORN_COLOR.darkened(0.2))


## Quien salga de la arena se pincha con las zarzas.
func _tick_arena(delta: float) -> void:
	for champion: Player in run.alive_players():
		if champion.pos.distance_to(arena_center) > arena_radius:
			champion.take_damage(THORN_DPS * delta, &"las zarzas")


# --- Proyectiles enemigos ---

func fire_projectile(from: Vector2, velocity: Vector2, damage: float, lifetime: float = 4.0) -> void:
	if _proj_count >= MAX_PROJECTILES:
		return
	_proj_pos[_proj_count] = from
	_proj_vel[_proj_count] = velocity
	_proj_life[_proj_count] = lifetime
	_proj_damage[_proj_count] = damage
	_proj_count += 1


func _build_projectiles() -> void:
	_proj_pos.resize(MAX_PROJECTILES)
	_proj_vel.resize(MAX_PROJECTILES)
	_proj_life.resize(MAX_PROJECTILES)
	_proj_damage.resize(MAX_PROJECTILES)
	_proj_multimesh = Draw2D.multimesh_2d(Draw2D.quad_mesh(Vector2(0.9, 0.9)), MAX_PROJECTILES, false, false, run.bounds)
	var instance := MultiMeshInstance2D.new()
	instance.multimesh = _proj_multimesh
	instance.texture = Draw2D.soft_disc_texture()
	instance.modulate = LEAF_COLOR
	run.air_fx.add_child(instance)
	_proj_buffer.resize(MAX_PROJECTILES * FLOATS_PER_INSTANCE)


func _tick_projectiles(delta: float) -> void:
	var alive := run.alive_players()
	var reach := PROJECTILE_HIT_RADIUS + Player.RADIUS
	var k := 0
	while k < _proj_count:
		_proj_life[k] -= delta
		var p := _proj_pos[k] + _proj_vel[k] * delta
		_proj_pos[k] = p
		var hit := false
		for champion: Player in alive:
			if champion.pos.distance_to(p) <= reach:
				champion.take_damage(_proj_damage[k], &"las hojas de la Madre Raíz")
				hit = true
				break
		if hit or _proj_life[k] <= 0.0 or not run.bounds.has_point(p):
			var last := _proj_count - 1
			_proj_pos[k] = _proj_pos[last]
			_proj_vel[k] = _proj_vel[last]
			_proj_life[k] = _proj_life[last]
			_proj_damage[k] = _proj_damage[last]
			_proj_count -= 1
			continue
		k += 1
	_render_projectiles()


func _render_projectiles() -> void:
	for k in _proj_count:
		Draw2D.write_xform(_proj_buffer, k * FLOATS_PER_INSTANCE, _proj_pos[k] + Vector2(0.0, -0.8),
			_proj_vel[k].angle(), 1.3, 0.8)
	_proj_multimesh.buffer = _proj_buffer
	_proj_multimesh.visible_instance_count = _proj_count


# --- Ayudas para patrones ---

func nearest_player() -> Player:
	var best: Player = null
	var best_d := INF
	var origin := pos2d()
	for champion: Player in run.alive_players():
		var d := champion.pos.distance_to(origin)
		if d < best_d:
			best_d = d
			best = champion
	return best if best != null else run.player


func random_point_in_arena(rng: RandomNumberGenerator, margin: float = 2.0) -> Vector2:
	var angle := rng.randf() * TAU
	var dist := sqrt(rng.randf()) * (arena_radius - margin)
	return arena_center + Vector2.from_angle(angle) * dist
