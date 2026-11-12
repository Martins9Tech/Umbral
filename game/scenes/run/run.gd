class_name Run
extends Node2D
## Partida: arena, campeones, horda, armas, XP, élites, cofres y UI.
## Mundo 2D: la lógica trabaja en metros (Vector2) y el nodo `world` está
## escalado a píxeles (PPM), así que todo lo que cuelga de él dibuja en metros.
## Toda la simulación se dirige desde aquí en un orden fijo por frame, para que
## los índices de enemigos sean estables mientras se reparte daño.
## Preparada para co-op (TECNICO §7): hay una lista de jugadores y cada uno
## recibe órdenes por su PlayerInput; `player` es solo el jugador local.

enum State { PLAYING, LEVEL_UP, CHEST, AUGMENT, MENU, PAUSED, OVER }

const ARENA_SIZE := 120.0
const MAX_ENEMY_RADIUS := 1.6
const PILLAR_COUNT := 14
## Píxeles por metro (a 1080p se ven unos 34 × 19 m).
const PPM := 56.0
const CAMERA_FOLLOW := 10.0
const MAX_FRAME_DELTA := 0.05
const DEBUG_SPAWN_AMOUNT := 500
const ELITE_XP_MULT := 10
const EXPLOSION_DELAY := 1.0
const EXPLOSION_RADIUS := 3.5
const EXPLOSION_DAMAGE := 35.0
const CHEST_MULTI_CHANCE := 0.25
const NOTICE_GOLD := Color(1.0, 0.82, 0.3)
## Nombres visibles de fuentes de daño que no son armas ni habilidades.
const OTHER_SOURCE_NAMES := {&"quemadura": "Quemaduras", &"combustion": "Combustión", &"espinas": "Espinas"}
const NOTICE_ELITE := Color(1.0, 0.55, 0.25)
const NOTICE_DANGER := Color(1.0, 0.35, 0.3)
const NOTICE_BOSS := Color(0.55, 1.0, 0.4)
const NOTICE_AUGMENT := Color(0.88, 0.45, 1.0)
const GOLD_DROP_CHANCE := 0.07
const ELITE_GOLD := 15
const HERALD_GOLD := 40
const CHEST_GOLD := 20
const FOOD_HEAL := 35.0
const BOMB_RADIUS := 18.0
const PROP_COUNT := 18
const PROP_RESPAWN_TIME := 25.0
const CONTRACT_KILLS := 250
const CONTRACT_TIME := 30.0
const CONTRACT_GOLD := 50
const MERCHANT_TIME := 75.0
const ALTAR_TIME := 90.0
const CONTRACT_STONE_TIME := 60.0
const AUGMENT_REROLLS := 1
const BOSS_RETREAT_TIME := 3.0
const BOSS_ARENA_RADIUS := 22.0
const HERALD_ATTACK_INTERVAL := 4.0
const HERALD_ROOT_DAMAGE := 22.0
const STAMPEDE_PER_PLAYER := 70
const MADRE_RAIZ := preload("res://entities/bosses/madre_raiz/madre_raiz.gd")
const AUTOTEST_WARMUP_FRAMES := 60
const AUTOTEST_FRAMES := 660
const AUTOTEST_BALANCE_LIMIT := 900.0
const GROUND_SHADER := preload("res://shaders/ground_forest_2d.gdshader")
const STONE := Color("6a5848")
const DARK_STONE := Color("3a302a")
const MOSS := Color("3b341a")

var state := State.PLAYING
var run_seed := 0
var rng_spawn := RandomNumberGenerator.new()
var rng_loot := RandomNumberGenerator.new()
var bounds := Rect2()
## Obstáculos circulares: (x, z, radio).
var obstacles: Array[Vector3] = []

# Capas de dibujo (de abajo arriba), todas hijas de `world`.
var world: Node2D
var ground_fx: Node2D
var air_fx: Node2D
var weapons_layer: Node2D
var _decor_low: Node2D
var _decor_high: Node2D
var _props_layer: Node2D
var _bosses_layer: Node2D
var _players_layer: Node2D

var swarm: EnemySwarm
var projectiles: ProjectileSystem
var gems: GemSystem
var chests: ChestSystem
var telegraphs: TelegraphSystem
var timeline := MapTimeline.new()
var boss: Boss
var vfx: VfxPool
var director: SpawnDirector
## Todos los campeones de la partida (co-op). El local es `player`.
var players: Array[Player] = []
var player: Player

# Experiencia y nivel compartidos por el grupo (TECNICO §7.4).
var elapsed := 0.0
var kills := 0
var level := 1
var xp := 0.0
var pending_level_ups := 0
var sim_usec := 0
var render_usec := 0

var _alive_index := PackedInt32Array()
var _explosions: Array[Dictionary] = []
var _pending_blasts: Array[Dictionary] = []
var _pending_augments := 0
var _next_augment_rarity := -1
# Oro (compartido por el grupo) y eventos
var gold := 0
var gold_earned := 0
var gold_spent := 0
var interactables: InteractableSystem
var telemetry := RunTelemetry.new()
var _pending_interaction := -1
var _menu_kind := -1
var _shop_offers: Array[Dictionary] = []
var _shop_sold: Array[bool] = []
var _shop_panel: ShopPanel
var _event_panel: EventPanel
var _contract_left := 0.0
var _contract_start_kills := 0
var _props: Array[Dictionary] = []
var _prop_respawn_left := PROP_RESPAWN_TIME
## Decorado procedural (provisional hasta tener su arte): pilares, árboles y setas.
const DECOR_DIR := "res://assets/sprites/decorado/"
var _pillars: Array[Vector3] = []  # (x, y, variante); el radio está en obstacles
var _trees: Array[Dictionary] = []
var _mushrooms: Array[Vector3] = []  # (x, y, tamaño) de cada grupo de setas
var _rocks: Array[Vector3] = []  # (x, y, ancho)
var _decor := {}
var _augment_options: Array[AugmentData] = []
var _augment_rerolls := 0
var _chest_queue: Array[Player] = []
var _evolution_notices: Dictionary = {}
var _boss_countdown := -1.0
var _herald_alive := false
var _herald_attack_left := 3.0
var _victory := false
var _boss_fight_start := 0.0
var _level_at_boss := 0
var _camera: Camera2D
var _camera_target := Vector2.ZERO
var _shake := 0.0
var _hud: Hud
var _level_up_panel: LevelUpPanel
var _chest_panel: ChestPanel
var _augment_panel: AugmentPanel
var _pause_menu: PauseMenu
var _summary_panel: SummaryPanel
var _debug: DebugOverlay
var _offer: Array[Dictionary] = []
var _using_gamepad := false
var _autotest := false
## Las pruebas automáticas ven todas las armas, desbloqueadas o no.
var unlock_everything := false
var gold_mult := 1.0
var _armory_rerolls := 0
var _settings_panel: SettingsPanel
var _autotest_frames := 0
var _autotest_sim_total := 0
var _autotest_sim_max := 0
var _autotest_render_total := 0
var _autotest_enemy_total := 0
var _autotest_max_enemies := 0
var _autotest_balance := false
var _autotest_bot := false
var _autotest_evo := false
var _autotest_showcase := false
var _autotest_boss := false


func _ready() -> void:
	# La pausa la gestiona la propia partida (estado), así la UI sigue viva.
	process_mode = Node.PROCESS_MODE_ALWAYS
	Engine.time_scale = 1.0
	run_seed = randi()
	rng_spawn.seed = run_seed
	rng_loot.seed = run_seed + 1
	var half := ARENA_SIZE * 0.5
	bounds = Rect2(-half, -half, ARENA_SIZE, ARENA_SIZE)

	_build_world()
	_build_environment()
	_build_arena()

	swarm = EnemySwarm.new()
	swarm.name = "EnemySwarm"
	world.add_child(swarm)
	world.move_child(swarm, _bosses_layer.get_index())
	swarm.setup(ContentDB.enemies, bounds, obstacles)
	swarm.enemy_died.connect(_on_enemy_died)

	projectiles = ProjectileSystem.new()
	projectiles.name = "Projectiles"
	air_fx.add_child(projectiles)
	projectiles.setup(bounds)

	gems = GemSystem.new()
	gems.name = "Gems"
	world.add_child(gems)
	world.move_child(gems, _props_layer.get_index())
	gems.setup(bounds)

	telegraphs = TelegraphSystem.new()
	telegraphs.name = "Telegraphs"
	ground_fx.add_child(telegraphs)

	chests = ChestSystem.new()
	chests.name = "Chests"
	_props_layer.add_child(chests)

	vfx = VfxPool.new()
	vfx.name = "Vfx"
	ground_fx.add_child(vfx)
	vfx.top = VfxPool.new()
	vfx.top.name = "VfxTop"
	air_fx.add_child(vfx.top)

	director = SpawnDirector.new(rng_spawn, ContentDB.enemies)

	interactables = InteractableSystem.new()
	interactables.name = "Interactables"
	_props_layer.add_child(interactables)

	var champion_entry := MetaContent.champion(GameSession.selected_champion)
	player = _add_player(load(champion_entry["kit"]) as GDScript)
	if OS.get_cmdline_user_args().has("--autotest"):
		unlock_everything = true
	else:
		_apply_armory()

	_build_camera()
	_hud = Hud.new()
	add_child(_hud)
	_level_up_panel = LevelUpPanel.new()
	add_child(_level_up_panel)
	_level_up_panel.chosen.connect(_on_upgrade_chosen)
	_chest_panel = ChestPanel.new()
	add_child(_chest_panel)
	_chest_panel.closed.connect(_on_chest_panel_closed)
	_augment_panel = AugmentPanel.new()
	add_child(_augment_panel)
	_augment_panel.chosen.connect(_on_augment_chosen)
	_augment_panel.reroll_requested.connect(_on_augment_reroll)
	_shop_panel = ShopPanel.new()
	add_child(_shop_panel)
	_shop_panel.buy_requested.connect(_on_shop_buy)
	_shop_panel.closed.connect(_on_shop_closed)
	_event_panel = EventPanel.new()
	add_child(_event_panel)
	_event_panel.decided.connect(_on_event_decided)
	_pause_menu = PauseMenu.new()
	add_child(_pause_menu)
	_pause_menu.resume_requested.connect(_resume)
	_pause_menu.restart_requested.connect(_restart)
	_pause_menu.menu_requested.connect(_to_menu)
	_pause_menu.settings_requested.connect(_open_settings_from_pause)
	_settings_panel = SettingsPanel.new()
	add_child(_settings_panel)
	_summary_panel = SummaryPanel.new()
	add_child(_summary_panel)
	_summary_panel.retry_requested.connect(_restart)
	_summary_panel.menu_requested.connect(_to_menu)
	_debug = DebugOverlay.new()
	add_child(_debug)
	_debug.visible = false
	_hud.notify("Cómo evolucionar un arma: súbela a nivel 8, consigue su reliquia y abre el cofre de una élite. Esc muestra las recetas.",
		NOTICE_GOLD, 12.0)

	_autotest = OS.get_cmdline_user_args().has("--autotest")
	if not _autotest or OS.get_cmdline_user_args().has("--bot") or OS.get_cmdline_user_args().has("--showcase"):
		_spawn_props(PROP_COUNT)
	if _autotest:
		_start_autotest()


func _add_player(kit_script: GDScript) -> Player:
	var new_player := Player.new()
	new_player.name = "Player%d" % players.size()
	_players_layer.add_child(new_player)
	new_player.setup(self, players.size(), kit_script)
	new_player.died.connect(_on_player_died)
	players.append(new_player)
	return new_player


func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		_using_gamepad = true
	elif event is InputEventMouseMotion or event is InputEventKey:
		_using_gamepad = false


func _process(delta: float) -> void:
	_handle_global_input()
	_debug.refresh(self)
	if _autotest_showcase:
		_tick_autotest()  # también en pausa, para la secuencia de capturas
	if state == State.OVER:
		for champion: Player in players:
			champion.advance_animation(delta)
	if state != State.PLAYING:
		return
	var dt := minf(delta, MAX_FRAME_DELTA)
	elapsed += dt
	var start_usec := Time.get_ticks_usec()

	# 1. Entrada y movimiento de los campeones
	_read_local_input(player.input)
	for champion: Player in players:
		if not champion.is_dead():
			champion.tick_movement(dt)

	# 2. Horda (reconstruye la rejilla: a partir de aquí los índices son estables)
	_update_swarm_targets()
	swarm.simulate(dt)
	for k in _alive_index.size():
		players[_alive_index[k]].take_damage(swarm.touching_dps[k] * dt, &"la horda")
	if state != State.PLAYING:
		return

	# 3. Kits y armas
	for champion: Player in players:
		if not champion.is_dead():
			champion.tick_combat(dt)
	projectiles.simulate(dt, self)
	_apply_pending_blasts()
	_tick_burns(dt)
	if boss != null:
		boss.tick(dt)
	telegraphs.tick(dt, self)
	if state != State.PLAYING:
		return

	# 4. Muertes, explosiones, oleadas, experiencia y cofres
	swarm.flush_dead()
	_tick_explosions(dt)
	director.tick(dt, self)
	timeline.tick(elapsed, self)
	_tick_boss_countdown(dt)
	_tick_herald(dt)
	for champion: Player in players:
		if champion.is_dead():
			continue
		var gained := gems.simulate(dt, champion.pos, champion.stats.get_stat(StatId.MAGNET))
		if gained > 0:
			_add_xp(gained, champion)
		_handle_pickups(champion)
	for opener: Player in chests.tick(dt, players):
		_chest_queue.append(opener)
	var interaction := interactables.tick(dt, players)
	if interaction >= 0:
		_pending_interaction = interaction
	_tick_contract(dt)
	_tick_props(dt)
	telemetry.tick(self)
	sim_usec = Time.get_ticks_usec() - start_usec

	# 5. Presentación
	var render_start := Time.get_ticks_usec()
	vfx.tick(dt)
	swarm.render()
	projectiles.render()
	gems.render(dt)
	render_usec = Time.get_ticks_usec() - render_start
	_update_camera(dt)
	_hud.refresh(self)
	_update_indicators()
	if _autotest and not _autotest_showcase:
		_tick_autotest()
	_check_pending_screens()


# --- Jugadores ---

func alive_players() -> Array[Player]:
	var out: Array[Player] = []
	for champion: Player in players:
		if not champion.is_dead():
			out.append(champion)
	return out


func random_alive_player(rng: RandomNumberGenerator) -> Player:
	var alive := alive_players()
	if alive.is_empty():
		return player
	return alive[rng.randi_range(0, alive.size() - 1)]


func _update_swarm_targets() -> void:
	_alive_index.clear()
	var targets := PackedVector2Array()
	for k in players.size():
		if not players[k].is_dead():
			_alive_index.append(k)
			targets.append(players[k].pos)
	swarm.targets = targets


# --- Combate ---

func is_valid_target(i: int) -> bool:
	return i >= 0 and i < swarm.count and swarm.hp[i] > 0.0


func hit_enemy(i: int, amount: float, source: StringName, knockback: Vector2, attacker: Player) -> void:
	var tags := ContentDB.tags_of(source)
	# Crítico (GDD §10.1): probabilidad y multiplicador del atacante (+ sinergia de Sombra).
	var crit := rng_loot.randf() < attacker.stats.get_stat(StatId.CRIT_CHANCE) + attacker.weapon_crit_bonus(tags)
	if crit:
		amount *= attacker.stats.get_stat(StatId.CRIT_DAMAGE)
	if not swarm.damage(i, amount, knockback * attacker.weapon_knock_mult(tags)):
		return
	attacker.record_damage(source, amount)
	attacker.notify_hit(amount, crit)
	# Ejecución (sinergia de Sombra): remata a los que quedan con poca vida.
	var threshold := attacker.weapon_execute_threshold(tags)
	if threshold > 0.0:
		execute_if_low(i, threshold, source, attacker)


## Remata a un enemigo (no jefe) si le queda menos de `threshold` de vida.
func execute_if_low(i: int, threshold: float, source: StringName, attacker: Player) -> void:
	if not is_valid_target(i) or swarm.flags[i] & EnemySwarm.FLAG_BOSS:
		return
	if swarm.damage_mult[i] <= 0.0 or swarm.hp[i] / swarm.max_hp[i] >= threshold:
		return
	var rest := swarm.hp[i] / swarm.damage_mult[i] + 1.0
	if swarm.damage(i, rest):
		attacker.record_damage(source, rest)


# --- Estados alterados (los aplican las armas elementales) ---

func burn_enemy(i: int, burn_per_second: float, duration: float, attacker: Player) -> void:
	var mult := attacker.burn_mult()
	swarm.apply_burn(i, burn_per_second * mult, duration * (1.3 if mult > 1.0 else 1.0), attacker.player_index)


## Ralentiza y, con la sinergia de Hielo, puede congelar.
func chill_enemy(i: int, duration: float, attacker: Player) -> void:
	swarm.apply_slow(i, attacker.slow_mult(), duration)
	var chance := attacker.freeze_chance()
	if chance > 0.0 and rng_loot.randf() < chance:
		swarm.apply_freeze(i, 1.5)


## Aturde con la sinergia de Rayo.
func shock_enemy(i: int, attacker: Player) -> void:
	var stun := attacker.stun_duration()
	if stun > 0.0:
		swarm.apply_freeze(i, stun)


func enemies_in_circle(center: Vector2, radius: float) -> PackedInt32Array:
	var out := PackedInt32Array()
	for i: int in swarm.grid.query(center, radius + MAX_ENEMY_RADIUS):
		if is_valid_target(i) and swarm.pos[i].distance_to(center) <= radius + swarm.radius_of(i):
			out.append(i)
	return out


func _tick_burns(delta: float) -> void:
	for i in swarm.count:
		if swarm.burn_time[i] <= 0.0:
			continue
		swarm.burn_time[i] -= delta
		var amount := swarm.burn_dps[i] * delta
		swarm.damage_over_time(i, amount)
		var owner_index := swarm.burn_owner[i]
		if owner_index < players.size():
			players[owner_index].record_damage(&"quemadura", amount)
		if swarm.burn_time[i] <= 0.0:
			swarm.burn_dps[i] = 0.0
			swarm.flags[i] &= ~EnemySwarm.FLAG_BURNING


func damage_circle(center: Vector2, radius: float, amount: float, knock: float,
		source: StringName, knock_origin: Vector2, attacker: Player) -> int:
	var hits := 0
	for i: int in swarm.grid.query(center, radius + MAX_ENEMY_RADIUS):
		if not is_valid_target(i):
			continue
		var p := swarm.pos[i]
		var reach := radius + swarm.radius_of(i)
		if p.distance_squared_to(center) > reach * reach:
			continue
		hit_enemy(i, amount, source, (p - knock_origin).normalized() * knock, attacker)
		hits += 1
	return hits


func damage_cone(origin: Vector2, direction: Vector2, reach: float, min_cos: float,
		amount: float, knock: float, source: StringName, attacker: Player) -> int:
	var hits := 0
	for i: int in swarm.grid.query(origin, reach + MAX_ENEMY_RADIUS):
		if not is_valid_target(i):
			continue
		var offset := swarm.pos[i] - origin
		var max_dist := reach + swarm.radius_of(i)
		if offset.length_squared() > max_dist * max_dist:
			continue
		var to_enemy := offset.normalized()
		if offset.length_squared() > 0.25 and to_enemy.dot(direction) < min_cos:
			continue
		hit_enemy(i, amount, source, to_enemy * knock, attacker)
		hits += 1
	return hits


func damage_segment(a: Vector2, b: Vector2, width: float, amount: float, knock: float,
		source: StringName, attacker: Player) -> int:
	var hits := 0
	var mid := (a + b) * 0.5
	var reach := a.distance_to(b) * 0.5 + width + MAX_ENEMY_RADIUS
	for i: int in swarm.grid.query(mid, reach):
		if not is_valid_target(i):
			continue
		var p := swarm.pos[i]
		var closest := Geometry2D.get_closest_point_to_segment(p, a, b)
		var max_dist := width + swarm.radius_of(i)
		if closest.distance_squared_to(p) > max_dist * max_dist:
			continue
		var away := p - closest
		if away.length_squared() < 0.0001:
			away = (b - a).orthogonal()
		hit_enemy(i, amount, source, away.normalized() * knock, attacker)
		hits += 1
	return hits


func find_nearest_enemy(origin: Vector2, max_range: float) -> int:
	var best := -1
	var best_sq := max_range * max_range
	for i: int in swarm.grid.query(origin, max_range):
		if not is_valid_target(i):
			continue
		var d2 := origin.distance_squared_to(swarm.pos[i])
		if d2 < best_sq:
			best_sq = d2
			best = i
	return best


func find_nearest_enemies(origin: Vector2, max_range: float, amount: int) -> PackedInt32Array:
	var candidates: Array[Vector2] = []  # (distancia², índice)
	var range_sq := max_range * max_range
	for i: int in swarm.grid.query(origin, max_range):
		if not is_valid_target(i):
			continue
		var d2 := origin.distance_squared_to(swarm.pos[i])
		if d2 <= range_sq:
			candidates.append(Vector2(d2, i))
	candidates.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
	var out := PackedInt32Array()
	for k in mini(amount, candidates.size()):
		out.append(int(candidates[k].y))
	return out


## Explosión de un jugador pedida en un momento inseguro (p. ej. al matar):
## se aplica en el siguiente paso de combate.
func queue_blast(center: Vector2, radius: float, amount: float, source: StringName, attacker: Player) -> void:
	_pending_blasts.append({"center": center, "radius": radius, "amount": amount, "source": source, "attacker": attacker})


func _apply_pending_blasts() -> void:
	var blasts := _pending_blasts
	_pending_blasts = []
	for blast: Dictionary in blasts:
		var center: Vector2 = blast["center"]
		var radius: float = blast["radius"]
		damage_circle(center, radius, blast["amount"], 6.0, blast["source"], center, blast["attacker"])
		vfx.disc(center, radius, Color(1.0, 0.5, 0.15, 0.45), 0.25)


func add_shake(amount: float) -> void:
	if not SaveManager.setting("screen_shake"):
		return
	_shake = maxf(_shake, amount)


## Explosión telegrafiada de las élites explosivas: aviso en rojo y daño al rato.
func _tick_explosions(delta: float) -> void:
	for k in range(_explosions.size() - 1, -1, -1):
		var explosion := _explosions[k]
		var time_left: float = explosion["time"]
		time_left -= delta
		explosion["time"] = time_left
		if time_left > 0.0:
			continue
		var p: Vector2 = explosion["pos"]
		for champion: Player in alive_players():
			if champion.pos.distance_to(p) <= EXPLOSION_RADIUS + Player.RADIUS:
				champion.take_damage(EXPLOSION_DAMAGE * swarm.hp_scale, &"una élite explosiva")
		vfx.disc(p, EXPLOSION_RADIUS, Color(1.0, 0.45, 0.2, 0.7), 0.3)
		add_shake(0.25)
		_explosions.remove_at(k)


# --- Nombres ---

func display_name_for(source: StringName, champion: Player = null) -> String:
	var weapon_data := ContentDB.get_weapon(source)
	if weapon_data != null:
		return weapon_data.display_name
	var owner_kit := (champion if champion != null else player).kit
	if owner_kit.source_names.has(source):
		return str(owner_kit.source_names[source])
	return str(OTHER_SOURCE_NAMES.get(source, source))


func time_text() -> String:
	var total := int(elapsed)
	return "%02d:%02d" % [floori(total / 60.0), total % 60]


# --- Experiencia, nivel y cofres ---

func xp_needed() -> float:
	var n := float(level - 1)
	return 5.0 + 10.0 * n + 0.6 * n * n


func _add_xp(amount: int, collector: Player) -> void:
	xp += amount * collector.stats.get_stat(StatId.XP_GAIN)
	while xp >= xp_needed():
		xp -= xp_needed()
		level += 1
		pending_level_ups += 1
		EventBus.level_up.emit(level)


## Pantallas que interrumpen la partida, por orden: cofres y luego nivel.
func _check_pending_screens() -> void:
	if state != State.PLAYING:
		return
	if not _chest_queue.is_empty():
		var opener: Player = _chest_queue.pop_front()
		var lines := _open_chest(opener)
		if _autotest:
			return
		state = State.CHEST
		_chest_panel.open(lines)
		return
	if _pending_augments > 0:
		_open_augment_choice()
		return
	if _pending_interaction >= 0:
		var kind := _pending_interaction
		_pending_interaction = -1
		_open_interaction(kind)
		if state != State.PLAYING:
			return
	_check_level_up()


func _check_level_up() -> void:
	if pending_level_ups <= 0 or state != State.PLAYING:
		return
	# Co-op (más adelante): cada jugador elige la suya; hoy solo el local.
	_offer = UpgradeOffer.generate(self, player, rng_loot, 3)
	if _autotest:
		var bot_choice := _offer[_bot_pick(_offer)]
		UpgradeOffer.apply(player, bot_choice)
		log_choice(&"nivel", str(bot_choice["title"]))
		pending_level_ups -= 1
		_check_evolution_notices()
		return
	state = State.LEVEL_UP
	_level_up_panel.open(level - pending_level_ups + 1, _offer)


func _on_upgrade_chosen(index: int) -> void:
	if state != State.LEVEL_UP or index < 0 or index >= _offer.size():
		return
	UpgradeOffer.apply(player, _offer[index])
	log_choice(&"nivel", str(_offer[index]["title"]))
	pending_level_ups -= 1
	_level_up_panel.close()
	state = State.PLAYING
	_hud.refresh(self)
	_check_evolution_notices()
	_check_pending_screens()


## Contenido del cofre: evolución si hay alguna lista; si no, 1 o 3 mejoras de
## lo que ya se tiene. Devuelve las líneas para el panel.
func _open_chest(opener: Player) -> PackedStringArray:
	var lines := PackedStringArray()
	var evolvable := opener.evolvable_weapons()
	if not evolvable.is_empty():
		var weapon := evolvable[0]
		var old_name := weapon.data.display_name
		opener.evolve_weapon(weapon)
		lines.append("EVOLUCIÓN:  %s  >  %s" % [old_name, weapon.data.display_name])
		lines.append(weapon.data.description)
		add_shake(0.3)
		_hud.show_banner("¡%s!" % weapon.data.display_name, 3.0)
		_hud.notify("¡%s ha evolucionado en %s!" % [old_name, weapon.data.display_name], NOTICE_GOLD)
		return lines
	add_gold(CHEST_GOLD)
	lines.append("+%d de oro" % CHEST_GOLD)
	var rolls := 3 if rng_loot.randf() < CHEST_MULTI_CHANCE else 1
	for _k in rolls:
		var option: Dictionary = UpgradeOffer.generate(self, opener, rng_loot, 1, true)[0]
		UpgradeOffer.apply(opener, option)
		lines.append("[%s]  %s" % [option["tag"], option["title"]])
	_check_evolution_notices()
	return lines


## Avisa de cada paso hacia una evolución, una sola vez por paso y arma.
func _check_evolution_notices() -> void:
	for weapon: Weapon in player.weapons:
		var data := weapon.data
		if weapon.is_evolved() or data.evolution == null:
			continue
		var has_relic := player.relic_level(data.evolution_relic) > 0
		var relic_name := UpgradeOffer.relic_display_name(data.evolution_relic)
		var step := ""
		var text := ""
		if weapon.is_max_level() and has_relic:
			step = "ready"
			text = "¡%s lista para evolucionar!\nDerrota una élite y abre su cofre." % data.display_name
		elif weapon.is_max_level():
			step = "max"
			text = "%s está al máximo.\nConsigue la reliquia %s para evolucionarla." % [data.display_name, relic_name]
		elif has_relic:
			step = "relic"
			text = "Tienes %s: sube %s a nivel %d para evolucionarla en %s." % [
				relic_name, data.display_name, data.max_level, data.evolution.display_name]
		if step.is_empty():
			continue
		var key := weapon.get_instance_id()
		if _evolution_notices.get(key, "") == step:
			continue
		_evolution_notices[key] = step
		_hud.notify(text, NOTICE_GOLD)


func _update_indicators() -> void:
	var targets: Array[Dictionary] = []
	var elites := 0
	_herald_alive = false
	for i in swarm.count:
		var enemy_flags := swarm.flags[i]
		if enemy_flags & EnemySwarm.FLAG_HERALD:
			_herald_alive = true
			var herald_pos := swarm.pos[i]
			targets.append({"world": Vector3(herald_pos.x, 3.2, herald_pos.y), "color": NOTICE_DANGER, "label": "HERALDO"})
		elif enemy_flags & EnemySwarm.FLAG_ELITE and elites < 4:
			var p := swarm.pos[i]
			targets.append({"world": Vector3(p.x, 2.5, p.y), "color": NOTICE_ELITE, "label": "ÉLITE"})
			elites += 1
	if boss != null and boss.is_alive():
		var bp := boss.pos2d()
		targets.append({"world": Vector3(bp.x, 8.5, bp.y), "color": NOTICE_BOSS, "label": "JEFE"})
	for p: Vector2 in chests.positions():
		targets.append({"world": Vector3(p.x, 1.5, p.y), "color": NOTICE_GOLD, "label": "COFRE"})
	targets.append_array(interactables.indicator_targets())
	_hud.set_indicators(world, targets)


func _on_chest_panel_closed() -> void:
	if state != State.CHEST:
		return
	state = State.PLAYING
	_hud.refresh(self)
	_check_pending_screens()


# --- Eventos ---

func on_elite_spawned(type_index: int, enemy_flags: int) -> void:
	var affixes := PackedStringArray()
	if enemy_flags & EnemySwarm.FLAG_FAST:
		affixes.append("Veloz")
	if enemy_flags & EnemySwarm.FLAG_ARMORED:
		affixes.append("Blindado")
	if enemy_flags & EnemySwarm.FLAG_EXPLOSIVE:
		affixes.append("Explosivo")
	_hud.show_banner("¡Élite!  %s  ·  %s" % [swarm.types[type_index].display_name, ", ".join(affixes)], 3.0)
	_hud.notify("¡Ha aparecido una élite (%s)! Sigue la flecha naranja y derrótala: suelta un cofre." % ", ".join(affixes),
		NOTICE_ELITE)


func on_phase_changed(phase_name: String) -> void:
	_hud.show_banner("Fase: %s" % phase_name, 3.0)


func on_timeline_event(kind: StringName) -> void:
	match kind:
		&"elite":
			director.spawn_elite(self)
		&"herald":
			director.spawn_herald(self)
			_hud.show_banner("¡EL HERALDO!", 3.0)
			notify_boss("¡Ha llegado el Heraldo de la Madre Raíz! Lanza raíces bajo tus pies: muévete cuando veas el círculo rojo.")
		&"augment":
			_pending_augments += 1
		&"altar":
			_spawn_interactable(InteractableSystem.Kind.ALTAR, ALTAR_TIME)
			_hud.notify("Ha aparecido un ALTAR DE SANGRE (flecha roja): vida máxima a cambio de un aumento Arcano.", InteractableSystem.COLORS[InteractableSystem.Kind.ALTAR])
		&"merchant":
			_spawn_interactable(InteractableSystem.Kind.MERCHANT, MERCHANT_TIME)
			_hud.show_banner("¡El Mercader ha llegado!", 3.0)
			_hud.notify("El MERCADER está cerca (flecha dorada) durante %d s. Gasta tu oro." % int(MERCHANT_TIME), NOTICE_GOLD)
		&"contract":
			_spawn_interactable(InteractableSystem.Kind.CONTRACT, CONTRACT_STONE_TIME)
			_hud.notify("Una PIEDRA DE CONTRATO (flecha azul) ofrece un reto con recompensa.", InteractableSystem.COLORS[InteractableSystem.Kind.CONTRACT])
		&"stampede":
			director.spawn_stampede(self, STAMPEDE_PER_PLAYER)
			_hud.show_banner("¡ESTAMPIDA!", 3.0)
			_hud.notify("¡Estampida! Te rodean: abre hueco con la Zancada o el Paso.", NOTICE_DANGER)
		&"boss":
			_begin_boss_arrival()


func notify_augment(text: String) -> void:
	_hud.notify(text, NOTICE_AUGMENT, 5.0)


## Aumento (GDD §5.5): 1 de 3 con un recambio gratis por elección.
func _open_augment_choice() -> void:
	_augment_options = AugmentOffer.generate(player, rng_loot, director.minute(), 3, _next_augment_rarity)
	_next_augment_rarity = -1
	if _augment_options.is_empty():
		_pending_augments = 0
		return
	if _autotest:
		_apply_augment(_augment_options[0])
		return
	_augment_rerolls = AUGMENT_REROLLS + _armory_rerolls
	state = State.AUGMENT
	_augment_panel.open(_augment_options, _augment_rerolls)


func _on_augment_chosen(index: int) -> void:
	if state != State.AUGMENT or index < 0 or index >= _augment_options.size():
		return
	_augment_panel.close()
	state = State.PLAYING
	_apply_augment(_augment_options[index])
	_check_pending_screens()


func _on_augment_reroll() -> void:
	if state != State.AUGMENT or _augment_rerolls <= 0:
		return
	_augment_rerolls -= 1
	_augment_options = AugmentOffer.generate(player, rng_loot, director.minute())
	_augment_panel.open(_augment_options, _augment_rerolls)


func _apply_augment(data: AugmentData) -> void:
	_pending_augments -= 1
	player.add_augment(data)
	log_choice(&"aumento", data.display_name)
	_hud.refresh(self)
	notify_augment("Aumento %s: %s" % [AugmentData.rarity_name(data.rarity), data.display_name])


func notify_boss(text: String) -> void:
	_hud.notify(text, NOTICE_BOSS, 8.0)


## Minuto 10: la horda se retira y emerge la jefa.
func _begin_boss_arrival() -> void:
	if boss != null or _boss_countdown >= 0.0:
		return
	director.boss_mode = true
	swarm.retreat_left = BOSS_RETREAT_TIME
	_boss_countdown = BOSS_RETREAT_TIME
	_hud.show_banner("La tierra tiembla...", BOSS_RETREAT_TIME)
	notify_boss("La horda se retira. ¡La Madre Raíz despierta!")
	add_shake(0.4)


func _tick_boss_countdown(delta: float) -> void:
	if _boss_countdown < 0.0:
		return
	_boss_countdown -= delta
	if _boss_countdown > 0.0:
		return
	_boss_countdown = -1.0
	swarm.clear_all_but_boss()
	var center := player.pos.clamp(bounds.position + Vector2.ONE * (BOSS_ARENA_RADIUS + 3.0),
		bounds.end - Vector2.ONE * (BOSS_ARENA_RADIUS + 3.0))
	var boss_pos := center + Vector2(0.0, -9.0)
	boss = MADRE_RAIZ.new() as Boss
	boss.name = "Boss"
	_bosses_layer.add_child(boss)
	boss.setup(self, boss_pos, center)
	_boss_fight_start = elapsed
	_level_at_boss = level
	_hud.show_banner("¡LA MADRE RAÍZ!", 3.0)
	notify_boss("No salgas del círculo de zarzas. Los círculos rojos del suelo avisan de sus ataques: apártate o usa el Paso.")


## Truco F9: salta al minuto 10 y llama a la jefa.
func _jump_to_boss() -> void:
	var target := MapTimeline.BOSS_TIME
	if elapsed < target:
		director.skip_time(target - elapsed)
		elapsed = target
	timeline.skip_to(elapsed)
	timeline.tick(elapsed, self)


## El Heraldo lanza raíces telegrafiadas bajo cada jugador (anticipa al jefe).
func _tick_herald(delta: float) -> void:
	if not _herald_alive:
		return
	_herald_attack_left -= delta
	if _herald_attack_left > 0.0:
		return
	_herald_attack_left = HERALD_ATTACK_INTERVAL
	for champion: Player in alive_players():
		telegraphs.circle(champion.pos, 2.2, 1.3, HERALD_ROOT_DAMAGE, 0.0, 0.0, &"el Heraldo")


func _on_boss_defeated() -> void:
	_victory = true
	if boss != null:
		boss.defeat()
	telegraphs.clear()
	swarm.clear_all_but_boss()
	director.rate_mult = 0.0
	add_shake(0.8)
	_hud.show_banner("¡VICTORIA!", 4.0)
	if _autotest_boss:
		print("[BOSS] VICTORIA en %.0f s de combate" % (elapsed - _boss_fight_start))
		get_tree().quit()
		return
	var saved := _save_telemetry("victoria")
	var meta := _record_meta(true)
	if _autotest_balance:
		_print_balance_result("victoria")
		get_tree().quit()
		return
	# Un momento para disfrutarlo y luego el resumen.
	get_tree().create_timer(2.5).timeout.connect(func() -> void:
		state = State.OVER
		_summary_panel.open(self, true, saved, meta))


## Elección del bot: lo que acerque una evolución, luego armas nuevas (hasta 4),
## luego subir armas, luego reliquias.
func _bot_pick(offer: Array[Dictionary]) -> int:
	var best := 0
	var best_score := -1.0
	for k in offer.size():
		var option := offer[k]
		var kind: StringName = option["kind"]
		var score := 1.0
		if option.get("evolution", false):
			score = 10.0
		elif kind == &"weapon_new" and player.weapons.size() < 4:
			score = 6.0
		elif kind == &"weapon_up":
			score = 5.0
		elif kind == &"relic":
			score = 4.0
		elif kind == &"technique":
			score = 3.0
		if score > best_score:
			best_score = score
			best = k
	return best


func _on_enemy_died(type_index: int, p: Vector2, enemy_flags: int) -> void:
	if enemy_flags & EnemySwarm.FLAG_PROP:
		_on_prop_broken(p, enemy_flags & EnemySwarm.FLAG_SILENT != 0)
		return
	if enemy_flags & EnemySwarm.FLAG_SILENT:
		return
	if enemy_flags & EnemySwarm.FLAG_BOSS:
		_on_boss_defeated()
		return
	kills += 1
	for champion: Player in alive_players():
		champion.notify_kill(p, enemy_flags)
	if enemy_flags & EnemySwarm.FLAG_HERALD:
		_hud.notify("¡Heraldo derrotado! Ha soltado un COFRE. La Madre Raíz despertará en el minuto 10.", NOTICE_GOLD)
		gems.spawn(p + Vector2(1.0, 0.0), HERALD_GOLD, GemSystem.Kind.GOLD)
	var xp_value := swarm.types[type_index].xp
	if enemy_flags & EnemySwarm.FLAG_ELITE:
		xp_value *= ELITE_XP_MULT
		chests.spawn(p)
		_hud.notify("Élite derrotada: ha soltado un COFRE. Recógelo (flecha dorada).", NOTICE_GOLD)
		gems.spawn(p + Vector2(-1.0, 0.5), ELITE_GOLD, GemSystem.Kind.GOLD)
	elif rng_loot.randf() < GOLD_DROP_CHANCE:
		gems.spawn(p + Vector2(0.4, 0.4), 1, GemSystem.Kind.GOLD)
	gems.spawn(p, xp_value)
	if enemy_flags & EnemySwarm.FLAG_BURNING:
		# Sinergia de Fuego 2: los que mueren ardiendo explotan.
		for champion: Player in alive_players():
			if champion.synergy_tier(&"fuego") >= 2:
				queue_blast(p, 2.5, 18.0 * champion.stats.get_stat(StatId.DAMAGE), &"quemadura", champion)
				break
	if enemy_flags & EnemySwarm.FLAG_EXPLOSIVE:
		_explosions.append({"pos": p, "time": EXPLOSION_DELAY})
		vfx.disc(p, EXPLOSION_RADIUS, Color(1.0, 0.2, 0.15, 0.35), EXPLOSION_DELAY)
		_hud.notify("¡Va a explotar! Sal del círculo rojo.", NOTICE_DANGER, 3.0)
	EventBus.enemy_killed.emit(type_index, p, enemy_flags)


func _on_player_died(_champion: Player) -> void:
	if not alive_players().is_empty():
		return  # En co-op la partida sigue mientras quede alguien en pie.
	state = State.OVER
	Engine.time_scale = 1.0
	var saved := _save_telemetry("derrota")
	var meta := _record_meta(false)
	if _autotest_balance:
		_print_balance_result("muere")
		get_tree().quit()
		return
	_summary_panel.open(self, false, saved, meta)


func _resume() -> void:
	if state == State.PAUSED:
		state = State.PLAYING
		_pause_menu.close()


func _restart() -> void:
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()


# --- Progresión permanente (GDD §9) ---

## Aplica las mejoras compradas en la Armería al empezar la partida.
func _apply_armory() -> void:
	for entry: Dictionary in MetaContent.ARMORY:
		var rank := SaveManager.armory_rank(entry["id"])
		if rank <= 0:
			continue
		var value: float = float(entry["value"]) * rank
		match entry["id"]:
			&"codicia":
				gold_mult += value
			&"recambio":
				_armory_rerolls = int(value)
			&"segunda_vida":
				player.revives = int(value)
			_:
				player.stats.add_modifier(entry["stat"], int(entry["kind"]) as Stats.Kind, value, &"armeria")
	player.reset_health()


## Resumen de la partida para logros y Esencia.
func end_of_run_stats(victory: bool) -> Dictionary:
	var evolutions := 0
	for weapon: Weapon in player.weapons:
		if weapon.is_evolved():
			evolutions += 1
	var max_synergy := 0
	for amount: Variant in player.synergy_counts.values():
		max_synergy = maxi(max_synergy, int(amount))
	return {
		"minutes": elapsed / 60.0, "seconds": int(elapsed), "kills": kills, "level": level,
		"gold": gold_earned, "gold_spent": gold_spent, "victory": victory,
		"evolutions": evolutions, "max_synergy": max_synergy,
	}


## Registra la partida en el progreso permanente (nunca en pruebas automáticas).
func _record_meta(victory: bool) -> Dictionary:
	if _autotest:
		return {}
	return SaveManager.process_run(end_of_run_stats(victory))


func _to_menu() -> void:
	GameSession.go_to_menu()


func _open_settings_from_pause() -> void:
	_settings_panel.open()


# --- Oro, objetos y rompibles (GDD §5.7-5.8) ---

func add_gold(amount: int) -> void:
	var final_amount := roundi(amount * gold_mult)
	gold += final_amount
	gold_earned += final_amount


func log_choice(kind: StringName, what: String) -> void:
	telemetry.log_choice(elapsed, kind, what)


func _handle_pickups(collector: Player) -> void:
	for pickup: Vector2i in gems.last_pickups:
		match pickup.x:
			GemSystem.Kind.GOLD:
				add_gold(pickup.y)
			GemSystem.Kind.FOOD:
				collector.heal(FOOD_HEAL)
				vfx.disc(collector.pos, 1.8, Color(1.0, 0.4, 0.45, 0.6), 0.4)
				_hud.notify("Comida: +%d de vida." % int(FOOD_HEAL), Color(1.0, 0.45, 0.5), 3.0)
			GemSystem.Kind.MAGNET:
				gems.attract_all()
				_hud.notify("¡Imán! Atraes toda la experiencia y el oro del mapa.", Color(0.4, 0.6, 1.0), 3.0)
			GemSystem.Kind.BOMB:
				_detonate_bomb(collector.pos)


## Bomba: arrasa a los enemigos normales cercanos y hiere a las élites.
func _detonate_bomb(center: Vector2) -> void:
	for i in swarm.count:
		if swarm.hp[i] <= 0.0 or swarm.flags[i] & (EnemySwarm.FLAG_BOSS | EnemySwarm.FLAG_PROP):
			continue
		if swarm.pos[i].distance_to(center) > BOMB_RADIUS:
			continue
		var amount := swarm.max_hp[i] * (0.25 if swarm.flags[i] & EnemySwarm.FLAG_ELITE else 10.0)
		swarm.damage(i, amount)
	vfx.disc(center, BOMB_RADIUS, Color(1.0, 0.6, 0.3, 0.5), 0.5)
	add_shake(0.6)
	_hud.notify("¡BOMBA! Has arrasado a los enemigos cercanos.", NOTICE_DANGER, 3.0)


func _spawn_prop(p: Vector2) -> void:
	if not swarm.spawn(0, p, EnemySwarm.FLAG_PROP, 1.0, 0.6, 0.0001):
		return
	_props.append({"pos": p})
	_props_layer.queue_redraw()


## Urnas rompibles (provisionales hasta tener su arte).
func _draw_props() -> void:
	for prop: Dictionary in _props:
		var p: Vector2 = prop["pos"]
		Draw2D.ellipse(_props_layer, p, 0.6, Color(0, 0, 0, 0.35))
		if _decor.get("urna") != null:
			Draw2D.sprite(_props_layer, _decor["urna"], p + Vector2(0.0, 0.1), 1.0)
			continue
		var body := PackedVector2Array([p + Vector2(-0.3, 0.0), p + Vector2(-0.45, -0.45), p + Vector2(-0.3, -0.9),
			p + Vector2(-0.2, -1.05), p + Vector2(0.2, -1.05), p + Vector2(0.3, -0.9), p + Vector2(0.45, -0.45),
			p + Vector2(0.3, 0.0)])
		_props_layer.draw_colored_polygon(body, Color(0.62, 0.45, 0.25))
		_props_layer.draw_polyline(body + PackedVector2Array([body[0]]), Color(0.25, 0.15, 0.08), 0.06)
		_props_layer.draw_line(p + Vector2(-0.42, -0.5), p + Vector2(0.42, -0.5), Color(0.45, 0.3, 0.15), 0.08)


func _spawn_props(amount: int) -> void:
	for _k in amount:
		for _attempt in 10:
			var p := Vector2(rng_spawn.randf_range(bounds.position.x + 4.0, bounds.end.x - 4.0),
				rng_spawn.randf_range(bounds.position.y + 4.0, bounds.end.y - 4.0))
			var blocked := false
			for o: Vector3 in obstacles:
				if p.distance_to(Vector2(o.x, o.y)) < o.z + 1.5:
					blocked = true
					break
			if not blocked:
				_spawn_prop(p)
				break


func _tick_props(delta: float) -> void:
	_prop_respawn_left -= delta
	if _prop_respawn_left <= 0.0:
		_prop_respawn_left = PROP_RESPAWN_TIME
		if _props.size() < PROP_COUNT and boss == null:
			_spawn_props(1)


func _on_prop_broken(p: Vector2, silent: bool) -> void:
	var best := -1
	var best_d := INF
	for k in _props.size():
		var d := p.distance_to(_props[k]["pos"])
		if d < best_d:
			best_d = d
			best = k
	if best >= 0:
		_props.remove_at(best)
		_props_layer.queue_redraw()
	if silent:
		return
	vfx.disc(p, 1.0, Color(0.9, 0.7, 0.4, 0.5), 0.25)
	var roll := rng_loot.randf()
	if roll < 0.4:
		gems.spawn(p, 1, GemSystem.Kind.FOOD)
	elif roll < 0.65:
		gems.spawn(p, 10, GemSystem.Kind.GOLD)
	elif roll < 0.85:
		gems.spawn(p, 1, GemSystem.Kind.MAGNET)
	else:
		gems.spawn(p, 1, GemSystem.Kind.BOMB)


# --- Eventos del mapa: altar, mercader y contrato ---

func _spawn_interactable(kind: InteractableSystem.Kind, lifetime: float) -> void:
	var angle := rng_spawn.randf() * TAU
	var p := player.pos + Vector2.from_angle(angle) * rng_spawn.randf_range(9.0, 13.0)
	p = p.clamp(bounds.position + Vector2.ONE * 4.0, bounds.end - Vector2.ONE * 4.0)
	for o: Vector3 in obstacles:
		var center := Vector2(o.x, o.y)
		if p.distance_to(center) < o.z + 3.0:
			p = center + (p - center).normalized() * (o.z + 3.0)
	interactables.spawn(kind, p, lifetime)


func _open_interaction(kind: int) -> void:
	if _autotest:
		return  # el bot no interactúa
	state = State.MENU
	match kind:
		InteractableSystem.Kind.MERCHANT:
			_shop_offers = ShopOffer.generate(self, player, rng_loot)
			_shop_sold.clear()
			for _k in _shop_offers.size():
				_shop_sold.append(false)
			_menu_kind = kind
			_shop_panel.open(_shop_offers, gold, _shop_sold)
		InteractableSystem.Kind.ALTAR:
			_menu_kind = kind
			_event_panel.open("ALTAR DE SANGRE",
				"Sacrifica el 20 % de tu vida máxima (para el resto de la partida)\na cambio de elegir un aumento ARCANO.",
				"Sacrificar", "Ahora no", InteractableSystem.COLORS[kind])
		InteractableSystem.Kind.CONTRACT:
			_menu_kind = kind
			_event_panel.open("CONTRATO",
				"Mata %d enemigos en %d segundos.\nRecompensa: un cofre y %d de oro." % [CONTRACT_KILLS, int(CONTRACT_TIME), CONTRACT_GOLD],
				"Aceptar el reto", "Ahora no", InteractableSystem.COLORS[kind])


func _on_shop_buy(index: int) -> void:
	if state != State.MENU or index < 0 or index >= _shop_offers.size() or _shop_sold[index]:
		return
	var offer := _shop_offers[index]
	var price: int = offer["price"]
	if gold < price:
		return
	gold -= price
	gold_spent += price
	_shop_sold[index] = true
	ShopOffer.apply(self, player, offer)
	_hud.refresh(self)
	_check_evolution_notices()
	_shop_panel.open(_shop_offers, gold, _shop_sold)


func _on_shop_closed() -> void:
	if state != State.MENU:
		return
	_shop_panel.close()
	state = State.PLAYING
	_check_pending_screens()


func _on_event_decided(accepted: bool) -> void:
	if state != State.MENU:
		return
	_event_panel.close()
	state = State.PLAYING
	if accepted:
		match _menu_kind:
			InteractableSystem.Kind.ALTAR:
				interactables.remove_kind(InteractableSystem.Kind.ALTAR)
				player.stats.add_modifier(StatId.MAX_HP, Stats.Kind.PERCENT, -0.2, &"altar_de_sangre")
				player.hp = minf(player.hp, player.max_hp())
				_next_augment_rarity = AugmentData.Rarity.ARCANO
				_pending_augments += 1
				log_choice(&"altar", "aceptado")
			InteractableSystem.Kind.CONTRACT:
				interactables.remove_kind(InteractableSystem.Kind.CONTRACT)
				_contract_left = CONTRACT_TIME
				_contract_start_kills = kills
				log_choice(&"contrato", "aceptado")
				_hud.notify("¡Contrato aceptado! Mata %d enemigos en %d s." % [CONTRACT_KILLS, int(CONTRACT_TIME)], InteractableSystem.COLORS[_menu_kind])
	_check_pending_screens()


func _tick_contract(delta: float) -> void:
	if _contract_left <= 0.0:
		_hud.set_contract("")
		return
	_contract_left -= delta
	var progress := kills - _contract_start_kills
	_hud.set_contract("CONTRATO  %d / %d   ·   %d s" % [mini(progress, CONTRACT_KILLS), CONTRACT_KILLS, ceili(_contract_left)])
	if progress >= CONTRACT_KILLS:
		_contract_left = 0.0
		chests.spawn(player.pos + Vector2(0.0, -3.0))
		add_gold(CONTRACT_GOLD)
		_hud.notify("¡Contrato cumplido! Cofre y %d de oro." % CONTRACT_GOLD, NOTICE_GOLD)
		log_choice(&"contrato", "cumplido")
	elif _contract_left <= 0.0:
		_hud.notify("Contrato fallado: no llegaste a tiempo.", NOTICE_DANGER)
		log_choice(&"contrato", "fallado")


func _save_telemetry(result: String) -> String:
	if _autotest and not _autotest_balance:
		return ""
	var mode := "bot" if _autotest_bot else ("quieto" if _autotest_balance else "jugador")
	return telemetry.save(self, result, mode)


# --- Entrada local ---

func _read_local_input(input: PlayerInput) -> void:
	input.move = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	input.aim = _compute_aim(input.move)
	input.technique_held = Input.is_action_pressed(&"technique")
	input.ultimate_pressed = Input.is_action_just_pressed(&"ultimate")
	input.dash_pressed = Input.is_action_just_pressed(&"dash")
	if _autotest_bot:
		input.move = _bot_move()
		input.aim = -input.move
		input.technique_held = true
		input.ultimate_pressed = true
		input.dash_pressed = false
	if (_autotest_bot or _autotest_boss) and boss != null and boss.is_alive():
		# Contra la jefa, el bot se queda a media distancia dentro de la arena.
		var to_boss := boss.pos2d() - player.pos
		input.move = to_boss.normalized() if to_boss.length() > 5.0 else Vector2.ZERO
		input.aim = to_boss.normalized()
		input.technique_held = true
		input.ultimate_pressed = true


func _compute_aim(move: Vector2) -> Vector2:
	var stick := Input.get_vector(&"aim_left", &"aim_right", &"aim_up", &"aim_down")
	if stick.length_squared() > 0.09:
		return stick.normalized()
	if _using_gamepad:
		if move.length_squared() > 0.04:
			return move.normalized()
		return player.aim_dir
	# El ratón en metros del mundo; se apunta desde el pecho del campeón.
	var to_mouse := world.get_local_mouse_position() - (player.pos + Vector2(0.0, -1.0))
	if to_mouse.length_squared() > 0.04:
		return to_mouse.normalized()
	return player.aim_dir


func _handle_global_input() -> void:
	if Input.is_action_just_pressed(&"pause"):
		if state == State.PLAYING:
			state = State.PAUSED
			_pause_menu.open(self)
		elif state == State.PAUSED:
			_resume()
	if Input.is_action_just_pressed(&"debug_overlay"):
		_debug.visible = not _debug.visible
	if state != State.PLAYING:
		return
	if Input.is_action_just_pressed(&"debug_spawn"):
		_debug_spawn(DEBUG_SPAWN_AMOUNT)
	if Input.is_action_just_pressed(&"debug_god"):
		player.god_mode = not player.god_mode
	if Input.is_action_just_pressed(&"debug_level"):
		level += 1
		pending_level_ups += 1
	if Input.is_action_just_pressed(&"debug_time"):
		director.skip_time(60.0)
		elapsed += 60.0
		timeline.skip_to(elapsed)
	if Input.is_action_just_pressed(&"debug_kill"):
		for i in swarm.count:
			swarm.damage(i, 1.0e9)
	if Input.is_action_just_pressed(&"debug_speed"):
		Engine.time_scale = 2.0 if Engine.time_scale < 1.5 else 1.0
	if Input.is_action_just_pressed(&"debug_elite"):
		director.spawn_elite(self)
	if Input.is_action_just_pressed(&"debug_augment"):
		_pending_augments += 1
	if Input.is_action_just_pressed(&"debug_boss") and boss == null and _boss_countdown < 0.0:
		_jump_to_boss()


func _debug_spawn(amount: int) -> void:
	for _k in amount:
		var angle := rng_spawn.randf() * TAU
		var dist := rng_spawn.randf_range(12.0, 30.0)
		var type_index := rng_spawn.randi_range(0, swarm.types.size() - 1)
		swarm.spawn(type_index, player.pos + Vector2.from_angle(angle) * dist)


# --- Escena ---

func _build_world() -> void:
	world = Node2D.new()
	world.name = "World"
	world.scale = Vector2.ONE * PPM
	# Los sprites se ven reducidos: mipmaps para que no parpadeen.
	world.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(world)
	_decor_low = _layer("DecorLow")
	_decor_low.draw.connect(_draw_decor_low)
	ground_fx = _layer("GroundFx")
	_props_layer = _layer("Props")
	_props_layer.draw.connect(_draw_props)
	_bosses_layer = _layer("Bosses")
	_players_layer = _layer("Players")
	_players_layer.y_sort_enabled = true
	weapons_layer = _layer("Weapons")
	air_fx = _layer("AirFx")
	_decor_high = _layer("DecorHigh")
	_decor_high.draw.connect(_draw_decor_high)


## Media vista en metros (lo que se ve desde el centro hasta cada borde).
func view_half_extents() -> Vector2:
	return get_viewport_rect().size / PPM * 0.5


func _layer(layer_name: String) -> Node2D:
	var node := Node2D.new()
	node.name = layer_name
	world.add_child(node)
	return node


## Estilo: GUIA_ESTILO.md (fantasía oscura). Penumbra general y luz cálida
## alrededor del campeón y de las setas: la magia es lo único que brilla.
func _build_environment() -> void:
	RenderingServer.set_default_clear_color(Color("120d0c"))
	var ambient := CanvasModulate.new()
	ambient.color = Color(0.9, 0.86, 0.86)
	add_child(ambient)


func _build_arena() -> void:
	# Suelo (más grande que la arena: el bosque sigue más allá de las ruinas).
	var ground := ColorRect.new()
	var extent := ARENA_SIZE * 0.5 + 30.0
	ground.position = Vector2(-extent, -extent)
	ground.size = Vector2(extent, extent) * 2.0
	var ground_material := ShaderMaterial.new()
	ground_material.shader = GROUND_SHADER
	ground_material.set_shader_parameter(&"pixels_per_meter", PPM)
	ground_material.set_shader_parameter(&"arena_half", ARENA_SIZE * 0.5 * PPM)
	ground.material = ground_material
	ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world.add_child(ground)
	world.move_child(ground, 0)

	for decor_name: String in ["pilar_1", "pilar_2", "arbol_1", "arbol_2", "arbol_3", "setas", "rocas", "urna"]:
		var path := DECOR_DIR + decor_name + ".png"
		_decor[decor_name] = load(path) if ResourceLoader.exists(path) else null

	# Pilares de piedra en ruinas (obstáculos), con musgo encima.
	var attempts := 0
	while obstacles.size() < PILLAR_COUNT and attempts < 500:
		attempts += 1
		var r := rng_spawn.randf_range(1.0, 2.2)
		var p := Vector2(
			rng_spawn.randf_range(bounds.position.x + 6.0, bounds.end.x - 6.0),
			rng_spawn.randf_range(bounds.position.y + 6.0, bounds.end.y - 6.0))
		if p.length() < 10.0:
			continue
		var overlaps := false
		for o: Vector3 in obstacles:
			if p.distance_to(Vector2(o.x, o.y)) < o.z + r + 4.0:
				overlaps = true
				break
		if overlaps:
			continue
		obstacles.append(Vector3(p.x, p.y, r))
		_pillars.append(Vector3(p.x, p.y, rng_spawn.randi_range(1, 2)))

	_build_forest_edge()
	_build_glowing_mushrooms()
	_build_rocks()


## Árboles otoñales fuera de las ruinas: forman la pared del bosque.
func _build_forest_edge() -> void:
	var leaf_colors: Array[Color] = []
	for hex: String in ["803214", "9a3d18", "6d2a12", "a8541c", "5a3a14"]:
		leaf_colors.append(Color(hex))
	var half := ARENA_SIZE * 0.5
	for _k in 160:
		var side := rng_spawn.randi_range(0, 3)
		var along := rng_spawn.randf_range(-half - 12.0, half + 12.0)
		var out := half + rng_spawn.randf_range(1.5, 16.0)
		var p := Vector2(along, -out)
		match side:
			1:
				p = Vector2(along, out)
			2:
				p = Vector2(-out, along)
			3:
				p = Vector2(out, along)
		_trees.append({"pos": p, "height": rng_spawn.randf_range(2.5, 4.5),
			"radius": rng_spawn.randf_range(1.8, 3.2),
			"color": leaf_colors[rng_spawn.randi_range(0, leaf_colors.size() - 1)],
			"variant": "arbol_%d" % rng_spawn.randi_range(1, 3), "flip": rng_spawn.randf() < 0.5})
	_trees.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["pos"].y < b["pos"].y)


## Setas luminosas ámbar con su luz.
func _build_glowing_mushrooms() -> void:
	var placed := 0
	var attempts := 0
	while placed < 18 and attempts < 200:
		attempts += 1
		var center := Vector2(
			rng_spawn.randf_range(bounds.position.x + 4.0, bounds.end.x - 4.0),
			rng_spawn.randf_range(bounds.position.y + 4.0, bounds.end.y - 4.0))
		if center.length() < 8.0:
			continue
		var blocked := false
		for o: Vector3 in obstacles:
			if center.distance_to(Vector2(o.x, o.y)) < o.z + 1.0:
				blocked = true
				break
		if blocked:
			continue
		placed += 1
		_mushrooms.append(Vector3(center.x, center.y, rng_spawn.randf_range(1.2, 2.0)))
		var light := PointLight2D.new()
		light.texture = Draw2D.radial_texture()
		light.texture_scale = 8.0 / Draw2D.RADIAL_SIZE
		light.color = Color("ffae3d")
		light.energy = 0.9
		light.position = center
		_decor_low.add_child(light)


## Rocas: un borde de piedras alrededor de la arena y algunas sueltas dentro.
func _build_rocks() -> void:
	var half := ARENA_SIZE * 0.5 + 0.6
	var along := -half
	while along < half:
		for side in 4:
			var p := Vector2(along, -half)
			match side:
				1:
					p = Vector2(along, half)
				2:
					p = Vector2(-half, along)
				3:
					p = Vector2(half, along)
			p += Vector2(rng_spawn.randf_range(-0.4, 0.4), rng_spawn.randf_range(-0.4, 0.4))
			_rocks.append(Vector3(p.x, p.y, rng_spawn.randf_range(2.0, 2.8)))
		along += rng_spawn.randf_range(1.8, 2.4)
	for _k in 45:
		var p := Vector2(rng_spawn.randf_range(bounds.position.x + 3.0, bounds.end.x - 3.0),
			rng_spawn.randf_range(bounds.position.y + 3.0, bounds.end.y - 3.0))
		var blocked := p.length() < 6.0
		for o: Vector3 in obstacles:
			if p.distance_to(Vector2(o.x, o.y)) < o.z + 2.0:
				blocked = true
				break
		if not blocked:
			_rocks.append(Vector3(p.x, p.y, rng_spawn.randf_range(0.9, 1.6)))
	_rocks.sort_custom(func(a: Vector3, b: Vector3) -> bool: return a.y < b.y)


## Suelo: borde de rocas, rocas sueltas, setas y pilares (ordenados por altura en pantalla).
func _draw_decor_low() -> void:
	if _decor.get("rocas") != null:
		for rock: Vector3 in _rocks:
			Draw2D.ellipse(_decor_low, Vector2(rock.x + 0.2, rock.y), rock.z * 0.45, Color(0, 0, 0, 0.3))
			Draw2D.sprite(_decor_low, _decor["rocas"], Vector2(rock.x, rock.y + 0.2), rock.z, int(rock.x * 7.0) % 2 == 0)
		for m: Vector3 in _mushrooms:
			Draw2D.sprite(_decor_low, _decor["setas"], Vector2(m.x, m.y), m.z, int(m.x) % 2 == 0)
		var order: Array[int] = []
		for k in _pillars.size():
			order.append(k)
		order.sort_custom(func(a: int, b: int) -> bool: return _pillars[a].y < _pillars[b].y)
		for k: int in order:
			var pillar := _pillars[k]
			var r: float = obstacles[k].z
			var base := Vector2(pillar.x, pillar.y)
			Draw2D.ellipse(_decor_low, base + Vector2(0.5, 0.1), r * 1.25, Color(0, 0, 0, 0.42))
			var variant := "pilar_%d" % int(pillar.z)
			Draw2D.sprite(_decor_low, _decor[variant], base + Vector2(0.0, r * 0.35), r * 2.5, int(base.x) % 2 == 0)
		return
	_draw_decor_low_fallback()


## Versión dibujada por código (si falta el arte).
func _draw_decor_low_fallback() -> void:
	var half := ARENA_SIZE * 0.5
	var wall := 1.2
	for k in 4:
		var rect := Rect2(-half - wall, -half - wall, ARENA_SIZE + wall * 2.0, wall)
		match k:
			1:
				rect = Rect2(-half - wall, half, ARENA_SIZE + wall * 2.0, wall)
			2:
				rect = Rect2(-half - wall, -half, wall, ARENA_SIZE)
			3:
				rect = Rect2(half, -half, wall, ARENA_SIZE)
		_decor_low.draw_rect(rect, DARK_STONE)
		_decor_low.draw_rect(rect, DARK_STONE.darkened(0.5), false, 0.12)
	for k in _pillars.size():
		var pillar := _pillars[k]
		var r: float = obstacles[k].z
		var base := Vector2(pillar.x, pillar.y)
		var height := pillar.z * 0.8
		Draw2D.ellipse(_decor_low, base + Vector2(0.4, 0.2), r * 1.2, Color(0, 0, 0, 0.4))
		var body := Rect2(base.x - r, base.y - height, r * 2.0, height)
		_decor_low.draw_rect(body, STONE.darkened(0.15))
		Draw2D.ellipse(_decor_low, base, r, STONE.darkened(0.15), 0.4)
		for row in int(height / 0.7):
			var y := base.y - 0.7 * (row + 1)
			_decor_low.draw_line(Vector2(base.x - r, y), Vector2(base.x + r, y), STONE.darkened(0.45), 0.06)
		Draw2D.ellipse(_decor_low, Vector2(base.x, base.y - height), r, STONE.lightened(0.05), 0.4)
		Draw2D.ellipse(_decor_low, Vector2(base.x, base.y - height - 0.05), r * 0.8, MOSS.lightened(0.1), 0.4)
	for m: Vector3 in _mushrooms:
		var p := Vector2(m.x, m.y)
		var size := m.z
		_decor_low.draw_line(p, p + Vector2(0.0, -0.4 * size), Color("c9b48a"), 0.12 * size)
		Draw2D.ellipse(_decor_low, p + Vector2(0.0, -0.45 * size), 0.26 * size, Color("ffae3d"), 0.55)
		Draw2D.ellipse(_decor_low, p + Vector2(0.0, -0.5 * size), 0.12 * size, Color(1.0, 0.9, 0.6), 0.55)


## Encima de todo: los árboles del borde del bosque.
func _draw_decor_high() -> void:
	for tree: Dictionary in _trees:
		var texture: Texture2D = _decor.get(str(tree["variant"]))
		if texture != null:
			var p: Vector2 = tree["pos"]
			var width: float = float(tree["radius"]) * 2.4
			Draw2D.ellipse(_decor_high, p + Vector2(0.6, 0.0), width * 0.4, Color(0, 0, 0, 0.35))
			Draw2D.sprite(_decor_high, texture, p, width, tree["flip"])
			continue
		var p: Vector2 = tree["pos"]
		var height: float = tree["height"]
		var radius: float = tree["radius"]
		var color: Color = tree["color"]
		Draw2D.ellipse(_decor_high, p + Vector2(0.5, 0.0), radius * 0.9, Color(0, 0, 0, 0.35))
		_decor_high.draw_rect(Rect2(p.x - 0.3, p.y - height, 0.6, height), Color("3a2618"))
		var top := p + Vector2(0.0, -height)
		_decor_high.draw_circle(top + Vector2(0.0, 0.3), radius, color.darkened(0.35))
		_decor_high.draw_circle(top + Vector2(-radius * 0.3, -radius * 0.2), radius * 0.7, color)
		_decor_high.draw_circle(top + Vector2(radius * 0.35, -radius * 0.05), radius * 0.6, color.lightened(0.08))


func _build_camera() -> void:
	_camera = Camera2D.new()
	add_child(_camera)
	_camera_target = player.pos
	_camera.position = _camera_target * PPM
	_camera.make_current()


func _update_camera(delta: float) -> void:
	# Un poco por encima de los pies: el campeón queda centrado en pantalla.
	var target := player.pos + Vector2(0.0, -1.0)
	_camera_target = _camera_target.lerp(target, 1.0 - exp(-CAMERA_FOLLOW * delta))
	_shake = maxf(0.0, _shake - delta)
	var jitter := Vector2.ZERO
	if _shake > 0.0:
		jitter = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake * 0.5
	_camera.position = (_camera_target + jitter) * PPM


# --- Pruebas automáticas (argumentos de usuario tras "--") ---
# --autotest            rendimiento con todas las armas
# --autotest --stress   rendimiento con 1.500 enemigos sostenidos
# --autotest --idle     dificultad: jugador quieto
# --autotest --bot      dificultad: bot que huye y usa habilidades

func _start_autotest() -> void:
	var args := OS.get_cmdline_user_args()
	if args.has("--idle") or args.has("--bot"):
		_autotest_balance = true
		_autotest_bot = args.has("--bot")
		player.god_mode = args.has("--god")
		return
	if args.has("--augments"):
		# Todos los aumentos a la vez con el bot, para cazar errores.
		_autotest_balance = true
		_autotest_bot = true
		player.god_mode = true
		for data: AugmentData in ContentDB.augments:
			player.add_augment(data)
		return
	if args.has("--boss"):
		# Jefe directo con una build fuerte, para capturas y pruebas.
		_autotest_boss = true
		player.god_mode = true
		for data: WeaponData in ContentDB.weapons:
			if not data.is_evolution and not player.has_weapon(data.id):
				player.add_weapon(data)
		for weapon: Weapon in player.weapons:
			for _k in 7:
				weapon.level_up()
		_jump_to_boss()
		_debug.visible = false
		return
	player.god_mode = true
	if args.has("--evo"):
		# Evolución: Cuchillas al máximo + Presteza, y un cofre a los pies.
		_autotest_evo = true
		player.add_weapon(ContentDB.get_weapon(&"cuchillas_orbitales"))
		var blades := player.get_weapon(&"cuchillas_orbitales")
		for _k in 7:
			blades.level_up()
		for relic: RelicData in ContentDB.relics:
			if relic.id == &"presteza":
				player.set_relic_level(relic, 1)
		chests.spawn(player.pos)
		director.rate_mult = 0.0
		return
	if args.has("--stress"):
		director.rate_mult = 0.0
		_debug_spawn(1500)
		return
	if args.has("--showcase"):
		# Escena para capturas: build variada, una élite y un cofre a la vista.
		_autotest_showcase = true
		for data: WeaponData in ContentDB.weapons:
			if not data.is_evolution and not player.has_weapon(data.id):
				player.add_weapon(data)
		for k in player.weapons.size():
			for _n in k * 2 + 1:
				player.weapons[k].level_up()
		for relic: RelicData in ContentDB.relics.slice(0, 3):
			player.set_relic_level(relic, 2)
		swarm.spawn(2, player.pos + Vector2(9.0, -4.0), EnemySwarm.FLAG_ELITE | EnemySwarm.FLAG_ARMORED)
		on_elite_spawned(2, EnemySwarm.FLAG_ELITE | EnemySwarm.FLAG_ARMORED)
		chests.spawn(player.pos + Vector2(-8.0, 3.0))
		_debug.visible = false
		return
	for data: WeaponData in ContentDB.weapons:
		if not data.is_evolution and not player.has_weapon(data.id):
			player.add_weapon(data)
	for weapon: Weapon in player.weapons:
		for _k in 4:
			weapon.level_up()
	director.rate_mult = 6.0
	_debug_spawn(1500)


func _tick_autotest() -> void:
	_autotest_frames += 1
	if _autotest_showcase:
		match _autotest_frames:
			20:
				for id: StringName in [&"coloso", &"furia"]:
					for data: AugmentData in ContentDB.augments:
						if data.id == id:
							player.add_augment(data)
			40:
				_augment_options = AugmentOffer.generate(player, rng_loot, 8.0)
				state = State.AUGMENT
				_augment_panel.open(_augment_options, 1)
			75:
				_augment_panel.close()
				state = State.PLAYING
			90:
				state = State.PAUSED
				_pause_menu.open(self)
			100:
				# Baja hasta las sinergias para la captura.
				_pause_menu._scroll.scroll_vertical = 1000
			105:
				_pause_menu.close()
				state = State.PLAYING
				add_gold(150)
				_spawn_interactable(InteractableSystem.Kind.MERCHANT, MERCHANT_TIME)
				_spawn_interactable(InteractableSystem.Kind.ALTAR, ALTAR_TIME)
				gems.spawn(player.pos + Vector2(3.0, 2.0), 1, GemSystem.Kind.FOOD)
				gems.spawn(player.pos + Vector2(-3.0, 2.5), 1, GemSystem.Kind.BOMB)
				gems.spawn(player.pos + Vector2(2.0, -3.0), 5, GemSystem.Kind.GOLD)
			120:
				_autotest = false
				_open_interaction(InteractableSystem.Kind.MERCHANT)
				_autotest = true
			135:
				_shop_panel.close()
				state = State.PLAYING
				_autotest = false
				_open_interaction(InteractableSystem.Kind.ALTAR)
				_autotest = true
			150:
				_event_panel.close()
				state = State.LEVEL_UP
				_offer = UpgradeOffer.generate(self, player, rng_loot, 3)
				_level_up_panel.open(level + 1, _offer)
			175:
				_level_up_panel.close()
				state = State.PLAYING
			180:
				get_tree().quit()
		return
	if _autotest_evo:
		if _autotest_frames == 30:
			var names := PackedStringArray()
			for weapon: Weapon in player.weapons:
				names.append("%s(%s)" % [weapon.data.display_name, "EVO" if weapon.is_evolved() else str(weapon.level)])
			print("[EVO] cofres_restantes=%d armas=%s" % [chests.count(), ", ".join(names)])
			get_tree().quit()
		return
	if _autotest_boss:
		if _autotest_frames % 600 == 0 and boss != null:
			print("[BOSS] t=%.0fs fase=%d vida=%d%% estado=%s telegrafias=%d enemigos=%d" % [
				elapsed - _boss_fight_start, boss.phase, roundi(boss.hp_fraction() * 100.0),
				boss.state_name(), telegraphs.count(), swarm.count])
		return
	if _autotest_balance:
		# --snaps: cada 10 s guarda una captura y cuenta los enemigos (diagnóstico).
		if OS.get_cmdline_user_args().has("--snaps") and _autotest_frames % 600 == 0:
			var dir := OS.get_user_data_dir().path_join("snaps")
			DirAccess.make_dir_recursive_absolute(dir)
			get_viewport().get_texture().get_image().save_png(dir.path_join("t%03d.png" % roundi(elapsed)))
			var near := 0
			var view := Rect2(player.pos - view_half_extents(), view_half_extents() * 2.0)
			var nearest := INF
			for i in swarm.count:
				if view.has_point(swarm.pos[i]):
					near += 1
				nearest = minf(nearest, swarm.pos[i].distance_to(player.pos))
			print("[SNAP] t=%.0fs enemigos=%d en_pantalla=%d mas_cercano=%.1fm muertes=%d pos=%s" % [
				elapsed, swarm.enemy_count(), near, nearest, kills, player.pos])
		if elapsed >= AUTOTEST_BALANCE_LIMIT:
			_print_balance_result("sobrevive")
			get_tree().quit()
		return
	_autotest_max_enemies = maxi(_autotest_max_enemies, swarm.count)
	if _autotest_frames > AUTOTEST_WARMUP_FRAMES:
		_autotest_sim_total += sim_usec
		_autotest_render_total += render_usec
		_autotest_enemy_total += swarm.count
		_autotest_sim_max = maxi(_autotest_sim_max, sim_usec)
	if _autotest_frames >= AUTOTEST_FRAMES:
		var measured := AUTOTEST_FRAMES - AUTOTEST_WARMUP_FRAMES
		print("[AUTOTEST] frames=%d enemigos_max=%d enemigos_medios=%d muertes=%d nivel=%d sim_media_ms=%.2f sim_max_ms=%.2f render_media_ms=%.2f" % [
			measured, _autotest_max_enemies, _autotest_enemy_total / measured, kills, level,
			_autotest_sim_total / 1000.0 / measured, _autotest_sim_max / 1000.0,
			_autotest_render_total / 1000.0 / measured])
		get_tree().quit()


func _print_balance_result(outcome: String) -> void:
	var evolved := PackedStringArray()
	for weapon: Weapon in player.weapons:
		if weapon.is_evolved():
			evolved.append(weapon.data.display_name)
	var boss_info := "-"
	if boss != null:
		boss_info = "fase %d, vida %d %%, %.0f s de combate, nivel al llegar %d" % [
			boss.phase, roundi(boss.hp_fraction() * 100.0), elapsed - _boss_fight_start, _level_at_boss]
	print("[BALANCE] modo=%s resultado=%s tiempo=%s nivel=%d muertes=%d evoluciones=%s jefe=%s" % [
		"bot" if _autotest_bot else "quieto", outcome, time_text(), level, kills,
		", ".join(evolved) if not evolved.is_empty() else "-", boss_info])


## Bot muy simple para medir la dificultad: huye de la horda, evita los
## bordes, recoge cofres cercanos y usa la Técnica y la Definitiva en cuanto puede.
func _bot_move() -> Vector2:
	var away := Vector2.ZERO
	for i: int in swarm.grid.query(player.pos, 7.0):
		if not is_valid_target(i):
			continue
		var offset := player.pos - swarm.pos[i]
		var d2 := maxf(offset.length_squared(), 0.25)
		away += offset / d2
	var to_center := -player.pos / (ARENA_SIZE * 0.5)
	var direction := away.normalized() + to_center * to_center.length() * 2.0
	var chest := chests.nearest_position(player.pos, 25.0)
	if chest.is_finite():
		direction += (chest - player.pos).normalized() * 1.5
	if direction.length_squared() < 0.01:
		direction = Vector2.from_angle(elapsed * 0.5)
	return direction.normalized()
