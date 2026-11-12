class_name SpawnDirector
extends RefCounted
## Director de oleadas por créditos (GDD §8.2): gana créditos según el tiempo,
## los gasta en enemigos fuera de cámara en pequeños grupos. Las élites, el
## Heraldo y la estampida los programa la línea de tiempo del mapa.

## Los enemigos nacen justo fuera de la vista (con este margen en metros).
const SPAWN_OFFSCREEN_MARGIN := 2.5
const SPAWN_MIN_DISTANCE := 12.0
const MAX_ALIVE := 1200
const MAX_SPAWNS_PER_FRAME := 40
const MAX_MIN_ALIVE := 400
const DOUBLE_AFFIX_MINUTE := 6.0
const ELITE_AFFIXES := [EnemySwarm.FLAG_FAST, EnemySwarm.FLAG_ARMORED, EnemySwarm.FLAG_EXPLOSIVE]
const HERALD_HP_MULT := 40.0
const HERALD_RADIUS := 2.0
const HERALD_DPS := 40.0
## Durante el jefe solo llega un goteo de enemigos.
const BOSS_RATE := 0.2

var elapsed := 0.0
var credits := 0.0
var rate_mult := 1.0
var boss_mode := false

var _rng: RandomNumberGenerator
var _types: Array[EnemyData]
var _pending_type := -1
var _cluster_center := Vector2.ZERO
var _cluster_left := 0


func _init(rng: RandomNumberGenerator, types: Array[EnemyData]) -> void:
	_rng = rng
	_types = types


func minute() -> float:
	return elapsed / 60.0


## Adelanta el reloj (trucos).
func skip_time(seconds: float) -> void:
	elapsed += seconds


func tick(delta: float, run: Run) -> void:
	elapsed += delta
	var m := minute()
	var rate := rate_mult * (BOSS_RATE if boss_mode else 1.0)
	credits += (2.0 + 2.6 * m + 0.25 * m * m) * rate * delta
	run.swarm.hp_scale = 1.0 + 0.2 * m + 0.02 * m * m
	# Densidad mínima: si la pantalla se vacía, el Director la rellena enseguida.
	var alive := run.swarm.enemy_count()
	var min_alive := mini(MAX_MIN_ALIVE, int(14.0 + 34.0 * m))
	if rate_mult > 0.0 and not boss_mode and alive < min_alive:
		credits += float(min_alive - alive) * 1.2 * delta
	if run.swarm.retreat_left > 0.0:
		return

	var spawned := 0
	while spawned < MAX_SPAWNS_PER_FRAME and run.swarm.enemy_count() < MAX_ALIVE:
		if _pending_type < 0:
			_pending_type = _pick_type(m)
			if _pending_type < 0:
				return
		var cost := _types[_pending_type].cost
		if credits < cost:
			return  # Se guarda el tipo elegido hasta poder pagarlo.
		credits -= cost
		run.swarm.spawn(_pending_type, _next_spawn_point(run))
		_pending_type = -1
		spawned += 1


## Élite con 1 afijo (2 a partir del minuto 6), lejos de los jugadores.
func spawn_elite(run: Run) -> void:
	var m := minute()
	var type_index := _pick_type(m)
	if type_index < 0:
		return
	var affixes: Array = ELITE_AFFIXES.duplicate()
	var enemy_flags := EnemySwarm.FLAG_ELITE
	var affix_count := 2 if m >= DOUBLE_AFFIX_MINUTE else 1
	for _k in affix_count:
		var pick := _rng.randi_range(0, affixes.size() - 1)
		enemy_flags |= int(affixes[pick])
		affixes.remove_at(pick)
	_cluster_left = 0  # La élite llega sola, desde un punto nuevo.
	var p := _next_spawn_point(run)
	if run.swarm.spawn(type_index, p, enemy_flags):
		run.on_elite_spawned(type_index, enemy_flags)


## Heraldo (GDD §7.4): el enemigo más grande, gigante y con mucha vida.
func spawn_herald(run: Run) -> void:
	var type_index := _types.size() - 1
	var hp := _types[type_index].max_hp * run.swarm.hp_scale * HERALD_HP_MULT
	_cluster_left = 0
	var p := _next_spawn_point(run)
	run.swarm.spawn(type_index, p, EnemySwarm.FLAG_ELITE | EnemySwarm.FLAG_HERALD,
		hp, HERALD_RADIUS, HERALD_DPS)


## Estampida: un anillo de enemigos alrededor de cada jugador que se cierra.
func spawn_stampede(run: Run, per_player: int) -> void:
	for champion: Player in run.alive_players():
		for k in per_player:
			var angle := TAU * k / per_player
			var p := champion.pos + Vector2.from_angle(angle) * 19.0
			run.swarm.spawn(_rng.randi_range(0, mini(1, _types.size() - 1)), p)


func _pick_type(m: float) -> int:
	var total := 0.0
	for enemy_type: EnemyData in _types:
		if enemy_type.min_minute <= m:
			total += enemy_type.weight
	if total <= 0.0:
		return -1
	var roll := _rng.randf() * total
	for i in _types.size():
		if _types[i].min_minute > m:
			continue
		roll -= _types[i].weight
		if roll <= 0.0:
			return i
	return 0


func _next_spawn_point(run: Run) -> Vector2:
	if _cluster_left <= 0:
		_cluster_left = _rng.randi_range(3, 7)
		var anchor := run.random_alive_player(_rng).pos
		var margin := Vector2(2.0, 2.0)
		var half := run.view_half_extents() + Vector2.ONE * SPAWN_OFFSCREEN_MARGIN
		for _attempt in 8:
			# Un punto del borde del rectángulo de la vista (algo más grande), al azar
			# según la longitud de cada lado: llegan por todos lados a la vez.
			var along := _rng.randf() * 2.0 * (half.x + half.y)
			var offset := Vector2.ZERO
			if along < half.x * 2.0:
				offset = Vector2(along - half.x, -half.y if _rng.randf() < 0.5 else half.y)
			else:
				offset = Vector2(-half.x if _rng.randf() < 0.5 else half.x, along - half.x * 2.0 - half.y)
			_cluster_center = (anchor + offset).clamp(run.bounds.position + margin, run.bounds.end - margin)
			# Cerca de los bordes del mapa el punto se acerca al jugador: se reintenta.
			if _cluster_center.distance_to(anchor) > SPAWN_MIN_DISTANCE:
				break
	_cluster_left -= 1
	return _cluster_center + Vector2(_rng.randf_range(-2.5, 2.5), _rng.randf_range(-2.5, 2.5))
