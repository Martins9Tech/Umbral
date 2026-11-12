class_name Player
extends Node2D
## Un campeón en la partida: posición, vida, kit, armas, reliquias y daño hecho.
## Preparado para co-op (TECNICO §7): hay uno por jugador y solo recibe órdenes
## a través de su PlayerInput. La lógica vive en `pos` (metros); el nodo 2D,
## hijo del mundo de Run (escalado a píxeles), es solo la representación.

signal died(player: Player)

const RADIUS := 0.5
const WEAPON_SLOTS := 5
const RELIC_SLOTS := 5
const DASH_DISTANCE := 4.5
const DASH_TIME := 0.15
const DASH_COOLDOWN := 3.0
const DASH_EXTRA_INVULNERABILITY := 0.1
const AIM_MARKER_DISTANCE := 2.5
const BASE_COLOR := Color("6a5848")  # piedra cálida (GUIA_ESTILO)
const STONE_COLOR := Color("a39a8f")  # piedra endurecida del Rasgo
const RING_COLOR := Color("5fd8ff")
const MAX_STONE_VISUALS := 5
const MARKER_READY_COLOR := Color(0.45, 0.85, 1.0, 0.9)
const MARKER_WAIT_COLOR := Color(0.6, 0.6, 0.65, 0.35)

var run: Run
var player_index := 0
var input := PlayerInput.new()
var stats := Stats.new()
var pos := Vector2.ZERO
var hp := 100.0
var move_input := Vector2.ZERO
var aim_dir := Vector2(0.0, 1.0)
var is_moving := false
## Inmóvil (p. ej. durante la Definitiva de Orrun).
var rooted := false
## Invulnerable por una habilidad.
var invulnerable := false
var god_mode := false
var dash_cooldown_left := 0.0

# --- Build ---
var kit: ChampionKit
var weapons: Array[Weapon] = []
var relic_levels: Dictionary = {}
var augments: Array[Augment] = []
## Armas por elemento (para las sinergias).
var synergy_counts: Dictionary = {}
var damage_by_source: Dictionary = {}
## Qué le hizo daño por última vez (para el registro y el resumen).
var last_damage_cause: StringName = &""
## Segundas oportunidades (Armería): al caer, vuelve con la mitad de la vida.
var revives := 0

var _weapons_root: Node2D
var _dash_time_left := 0.0
var _dash_velocity := Vector2.ZERO
var _invulnerable_left := 0.0
var _hurt_flash := 0.0
var _is_dead := false
var _stone_count := 0
var _technique_ready := false
var _ultimate_ready := false
var _time := 0.0
var _ultimate_scale := 1.0


func setup(p_run: Run, p_index: int, kit_script: GDScript) -> void:
	run = p_run
	player_index = p_index
	stats.set_base(StatId.MAX_HP, 100.0)
	stats.set_base(StatId.REGEN, 0.0)
	stats.set_base(StatId.ARMOR, 0.0)
	stats.set_base(StatId.MOVE_SPEED, 6.0)
	stats.set_base(StatId.DAMAGE, 1.0)
	stats.set_base(StatId.AREA, 1.0)
	stats.set_base(StatId.COOLDOWN, 1.0)
	stats.set_base(StatId.AMOUNT, 0.0)
	stats.set_base(StatId.MAGNET, 3.0)
	stats.set_base(StatId.XP_GAIN, 1.0)
	stats.set_base(StatId.CRIT_CHANCE, 0.05)
	stats.set_base(StatId.CRIT_DAMAGE, 1.5)
	stats.set_base(StatId.DASH_COOLDOWN, 1.0)
	stats.set_base(StatId.DAMAGE_TAKEN, 1.0)
	stats.set_base(StatId.SIZE, 1.0)
	EventBus.ability_cast.connect(_on_ability_cast)

	# Las armas viven en coordenadas de mundo, fuera del nodo del jugador.
	_weapons_root = Node2D.new()
	_weapons_root.name = "Weapons_P%d" % p_index
	run.weapons_layer.add_child(_weapons_root)

	kit = kit_script.new() as ChampionKit
	kit.name = "Kit"
	add_child(kit)
	kit.setup(run, self)
	_build_visual()
	hp = max_hp()
	add_weapon(ContentDB.get_weapon(kit.signature_weapon_id()))


# --- Estado ---

func max_hp() -> float:
	return stats.get_stat(StatId.MAX_HP)


func reset_health() -> void:
	hp = max_hp()


func is_dead() -> bool:
	return _is_dead


func is_dashing() -> bool:
	return _dash_time_left > 0.0


# --- Simulación (la dirige Run en este orden) ---

## Antes de mover la horda: entrada, esquiva y desplazamiento.
func tick_movement(delta: float) -> void:
	move_input = input.move
	if input.aim.length_squared() > 0.0001:
		aim_dir = input.aim.normalized()
	if input.dash_pressed:
		try_dash()
	dash_cooldown_left = maxf(0.0, dash_cooldown_left - delta)
	_invulnerable_left = maxf(0.0, _invulnerable_left - delta)
	is_moving = false
	if is_dashing():
		pos += _dash_velocity * delta
		_dash_time_left -= delta
		is_moving = true
	elif not rooted and move_input.length_squared() > 0.01:
		pos += move_input.limit_length(1.0) * stats.get_stat(StatId.MOVE_SPEED) * delta
		is_moving = true
	pos = _resolve_collisions(pos)
	var regen := stats.get_stat(StatId.REGEN)
	if regen > 0.0:
		hp = minf(max_hp(), hp + regen * delta)


## Después de mover la horda (índices estables): kit y armas.
func tick_combat(delta: float) -> void:
	if input.technique_held:
		kit.try_technique(aim_dir)
	if input.ultimate_pressed:
		kit.try_ultimate(aim_dir)
	kit.tick(delta)
	_technique_ready = kit.technique_cooldown_left <= 0.0
	_ultimate_ready = kit.ultimate_ready() and not kit.ultimate_active()
	for weapon: Weapon in weapons:
		weapon.tick(delta)
	for augment: Augment in augments:
		augment.tick(delta)
	_update_visual(delta)


## Desplazamiento rápido e invulnerable (lo usan el Paso y algunas Técnicas).
func start_dash(direction: Vector2, distance: float, duration: float) -> void:
	if direction.length_squared() < 0.0001:
		direction = aim_dir
	_dash_velocity = direction.normalized() * (distance / duration)
	_dash_time_left = duration
	_invulnerable_left = maxf(_invulnerable_left, duration + DASH_EXTRA_INVULNERABILITY)


## Paso: esquiva común a todos los campeones (GDD §4.1).
func try_dash() -> void:
	if dash_cooldown_left > 0.0 or rooted or is_dashing():
		return
	var direction := move_input if move_input.length_squared() > 0.01 else aim_dir
	start_dash(direction, DASH_DISTANCE, DASH_TIME)
	dash_cooldown_left = dash_cooldown_max()


func dash_cooldown_max() -> float:
	return DASH_COOLDOWN * stats.get_stat(StatId.DASH_COOLDOWN)


func take_damage(amount: float, cause: StringName = &"la horda") -> void:
	if amount <= 0.0 or _is_dead or god_mode or invulnerable or _invulnerable_left > 0.0:
		return
	var armor := maxf(stats.get_stat(StatId.ARMOR), 0.0)
	var final_amount := amount * 100.0 / (100.0 + armor) * kit.damage_taken_multiplier() \
		* stats.get_stat(StatId.DAMAGE_TAKEN)
	hp -= final_amount
	last_damage_cause = cause
	_hurt_flash = 0.12
	EventBus.player_damaged.emit(self, final_amount)
	for augment: Augment in augments:
		augment.on_damaged(final_amount)
	if hp <= 0.0 and revives > 0:
		revives -= 1
		hp = max_hp() * 0.5
		_invulnerable_left = 2.5
		run.vfx.disc(pos, 4.0, Color(0.5, 1.0, 0.6, 0.6), 0.8)
		run.notify_augment("¡Segunda Oportunidad! Vuelves con la mitad de la vida.")
		return
	if hp <= 0.0:
		hp = 0.0
		_is_dead = true
		if _visual != null:
			_visual.call(&"morir")
		died.emit(self)
		return
	if _visual != null:
		_visual.call(&"herido")


func heal(amount: float) -> void:
	hp = minf(max_hp(), hp + amount)


func record_damage(source: StringName, amount: float) -> void:
	damage_by_source[source] = float(damage_by_source.get(source, 0.0)) + amount


# --- Build: armas ---

func add_weapon(data: WeaponData) -> void:
	if data == null or data.behaviour == null:
		push_error("Arma sin datos o sin comportamiento")
		return
	var weapon := data.behaviour.new() as Weapon
	weapon.name = String(data.id)
	_weapons_root.add_child(weapon)
	weapon.setup(data, run, self)
	weapons.append(weapon)
	_recount_synergies()


func has_weapon(id: StringName) -> bool:
	return get_weapon(id) != null


func get_weapon(id: StringName) -> Weapon:
	for weapon: Weapon in weapons:
		if weapon.data.id == id:
			return weapon
		# Un arma evolucionada sigue "siendo" la original a efectos del pool.
		if weapon.base_id == id:
			return weapon
	return null


func free_weapon_slots() -> int:
	var used := 0
	for weapon: Weapon in weapons:
		if not weapon.data.is_signature:
			used += 1
	return WEAPON_SLOTS - used


## Armas listas para evolucionar: nivel máximo + reliquia requerida.
func evolvable_weapons() -> Array[Weapon]:
	var out: Array[Weapon] = []
	for weapon: Weapon in weapons:
		if weapon.can_evolve():
			out.append(weapon)
	return out


func evolve_weapon(weapon: Weapon) -> void:
	var evolved_data := weapon.data.evolution
	weapon.evolve(evolved_data)
	_recount_synergies()
	EventBus.weapon_evolved.emit(self, evolved_data.display_name)


# --- Sinergias (GDD §5.6) ---

func synergy_count(tag: StringName) -> int:
	return int(synergy_counts.get(tag, 0))


func synergy_tier(tag: StringName) -> int:
	return Synergies.tier_for(synergy_count(tag))


func _recount_synergies() -> void:
	synergy_counts.clear()
	for weapon: Weapon in weapons:
		for tag: StringName in Synergies.elements_of(weapon.data.tags):
			synergy_counts[tag] = synergy_count(tag) + 1


## Multiplicador de daño de un arma según sus etiquetas.
func weapon_damage_mult(tags: Array[StringName]) -> float:
	var mult := 1.0
	if tags.has(&"fisico") and synergy_tier(&"fisico") >= 1:
		mult += 0.15
	if tags.has(&"rayo") and synergy_tier(&"rayo") >= 2:
		mult += 0.2
	return mult


func weapon_area_mult(tags: Array[StringName]) -> float:
	return 1.15 if tags.has(&"fisico") and synergy_tier(&"fisico") >= 2 else 1.0


func weapon_knock_mult(tags: Array[StringName]) -> float:
	return 1.3 if tags.has(&"fisico") and synergy_tier(&"fisico") >= 2 else 1.0


func weapon_crit_bonus(tags: Array[StringName]) -> float:
	return 0.12 if tags.has(&"sombra") and synergy_tier(&"sombra") >= 1 else 0.0


func weapon_execute_threshold(tags: Array[StringName]) -> float:
	return 0.12 if tags.has(&"sombra") and synergy_tier(&"sombra") >= 2 else 0.0


func burn_mult() -> float:
	return 1.5 if synergy_tier(&"fuego") >= 1 else 1.0


## Multiplicador de velocidad que deja la ralentización de hielo.
func slow_mult() -> float:
	return 0.35 if synergy_tier(&"hielo") >= 1 else 0.6


func freeze_chance() -> float:
	return 0.15 if synergy_tier(&"hielo") >= 2 else 0.0


func chain_bonus() -> int:
	return 1 if synergy_tier(&"rayo") >= 1 else 0


func stun_duration() -> float:
	return 0.4 if synergy_tier(&"rayo") >= 2 else 0.0


# --- Build: aumentos ---

func add_augment(data: AugmentData) -> void:
	var old_max_hp := max_hp()
	var augment: Augment = data.behaviour.new() if data.behaviour != null else Augment.new()
	augment.setup(data, run, self)
	augments.append(augment)
	var gained := max_hp() - old_max_hp
	if gained > 0.0:
		heal(gained)


func has_augment(id: StringName) -> bool:
	for augment: Augment in augments:
		if augment.data.id == id:
			return true
	return false


func notify_hit(amount: float, was_crit: bool) -> void:
	for augment: Augment in augments:
		augment.on_hit(amount, was_crit)


func notify_kill(p: Vector2, flags: int) -> void:
	for augment: Augment in augments:
		augment.on_kill(p, flags)


func _on_ability_cast(caster: Node, ability_id: StringName) -> void:
	if caster != self:
		return
	for augment: Augment in augments:
		augment.on_ability_cast(ability_id)


# --- Build: reliquias ---

func free_relic_slots() -> int:
	return RELIC_SLOTS - relic_levels.size()


func relic_level(id: StringName) -> int:
	return int(relic_levels.get(id, 0))


func set_relic_level(relic: RelicData, new_level: int) -> void:
	var old_max_hp := max_hp()
	relic_levels[relic.id] = new_level
	stats.remove_source(relic.id)
	stats.add_modifier(relic.stat, relic.kind, relic.value_per_level * new_level, relic.id)
	var gained := max_hp() - old_max_hp
	if gained > 0.0:
		heal(gained)


# --- Visual 2D ---
# Coordenadas locales en metros (el mundo de Run está escalado a píxeles).
# Debajo de los pies, dibujado aquí: sombra, anillo cian (como el círculo de
# selección de un MOBA, GUIA_ESTILO §3), anillo dorado de Definitiva, rocas del
# Rasgo y marca de apuntado. Encima, el dibujo del campeón (marioneta).

## Acciones del juego -> acciones de la marioneta.
const ACTION_ALIASES := {&"attack": &"punetazo", &"cast": &"golpe_tierra",
	&"dash": &"paso", &"technique": &"zancada"}

var _visual: Node2D
var _visual_base_scale := 1.0
var _light: PointLight2D


## Rocas visibles a los pies que muestran las capas del Rasgo (p. ej. Piedra de Orrun).
func set_stone_count(amount: int) -> void:
	_stone_count = clampi(amount, 0, MAX_STONE_VISUALS)


func set_ultimate_visual(active: bool) -> void:
	_ultimate_scale = 1.35 if active else 1.0


func _resolve_collisions(p: Vector2) -> Vector2:
	for o: Vector3 in run.obstacles:
		var center := Vector2(o.x, o.y)
		var offset := p - center
		var min_dist := o.z + RADIUS
		if offset.length_squared() < min_dist * min_dist:
			p = center + offset.normalized() * min_dist
	var margin := Vector2(RADIUS, RADIUS)
	return p.clamp(run.bounds.position + margin, run.bounds.end - margin)


func _build_visual() -> void:
	_visual = kit.create_visual()
	if _visual != null:
		_visual.set(&"auto_avanzar", false)
		_visual.set(&"capa_fantasmas", run.ground_fx)
		add_child(_visual)
		_visual_base_scale = kit.visual_height / float(_visual.get(&"altura"))
		if _visual.has_signal(&"impacto"):
			_visual.connect(&"impacto", _on_visual_impact)
		if _visual.has_signal(&"pisada"):
			_visual.connect(&"pisada", _on_visual_step)
	# Luz propia cálida: el campeón siempre se distingue en la penumbra.
	_light = PointLight2D.new()
	_light.texture = Draw2D.radial_texture()
	_light.texture_scale = 13.0 / Draw2D.RADIAL_SIZE
	_light.color = Color("ffb870")
	_light.energy = 0.7
	_light.position = Vector2(0.0, -1.0)
	add_child(_light)


## Efectos cuando el golpe de la animación conecta (además del daño del arma).
func _on_visual_impact(action: StringName, where: Vector2) -> void:
	var p := run.world.to_local(where)
	var ground := pos + (p - pos) * Vector2(1.0, 0.0) + Vector2(0.0, -0.2)
	match action:
		&"punetazo", &"martillo":
			run.vfx.disc(p, 0.9, Color(1.0, 0.75, 0.3, 0.8), 0.14)
			run.vfx.disc(ground, 1.6, Color(1.0, 0.6, 0.2, 0.35), 0.25)
			for k in 5:
				var dir := Vector2.from_angle(TAU * k / 5.0 + _time)
				run.vfx.line(p + dir * 0.3, p + dir * 1.3, 0.12, Color(1.0, 0.85, 0.45, 0.9), 0.12)
			run.add_shake(0.12)
		&"golpe_tierra":
			run.vfx.disc(pos, 2.6, Color(0.75, 0.6, 0.45, 0.55), 0.35)
		&"zancada":
			run.vfx.disc(pos, 1.6, Color(0.6, 0.5, 0.4, 0.5), 0.3)
			run.add_shake(0.15)


## Polvo al pisar.
func _on_visual_step(where: Vector2) -> void:
	var p := run.world.to_local(where)
	run.vfx.disc(Vector2(p.x, pos.y), 0.45, Color(0.55, 0.47, 0.38, 0.45), 0.3)


func has_visual() -> bool:
	return _visual != null


## Animación puntual: attack, cast, dash, technique (o un nombre de la marioneta).
func play_action(action: StringName, _speed: float = 1.0) -> void:
	if _visual == null or _is_dead:
		return
	_visual.call(&"accion", ACTION_ALIASES.get(action, action))


## Sigue animando aunque la partida haya terminado (p. ej. la caída al morir).
func advance_animation(delta: float) -> void:
	if _visual != null:
		_visual.call(&"avanzar", delta)


func _update_visual(delta: float) -> void:
	position = pos
	_time += delta
	_hurt_flash = maxf(0.0, _hurt_flash - delta)
	if _visual != null:
		var facing_x := move_input.x if is_moving and absf(move_input.x) > 0.2 else aim_dir.x
		if absf(facing_x) > 0.15:
			_visual.set(&"facing", signf(facing_x))
		var speed_ratio := stats.get_stat(StatId.MOVE_SPEED) / 6.0
		_visual.set(&"movimiento", speed_ratio if is_moving and not is_dashing() else 0.0)
		# Se vuelve de piedra con las capas del Rasgo; más claro si es invulnerable.
		var tint := Color.WHITE.lerp(STONE_COLOR * 1.3, 0.5 * _stone_count / float(MAX_STONE_VISUALS))
		if invulnerable or _invulnerable_left > 0.0:
			tint = tint.lightened(0.3)
		_visual.set(&"tinte", tint)
		_visual.scale = Vector2.ONE * _visual_base_scale * _ultimate_scale * stats.get_stat(StatId.SIZE)
		_visual.call(&"avanzar", delta)
	queue_redraw()


func _draw() -> void:
	var size := _ultimate_scale * stats.get_stat(StatId.SIZE)
	# Sombra y anillo de selección (elipses: el suelo se ve un poco inclinado).
	Draw2D.ellipse(self, Vector2.ZERO, 0.95 * size, Color(0.0, 0.0, 0.0, 0.4))
	Draw2D.ellipse_ring(self, Vector2.ZERO, 0.9 * size, 0.07, Color(RING_COLOR, 0.9))
	if _ultimate_ready:
		var pulse := 1.0 + 0.08 * sin(_time * 6.0)
		Draw2D.ellipse_ring(self, Vector2.ZERO, 1.25 * size * pulse, 0.1, Color(1.0, 0.8, 0.25, 0.95))
	for k in _stone_count:
		var angle := TAU * k / MAX_STONE_VISUALS - PI / 2.0
		var at := Vector2(cos(angle) * 1.05, sin(angle) * 0.5) * size
		Draw2D.rock(self, at, 0.2, STONE_COLOR)
	# Marca de apuntado: grande y azul cuando la Técnica está lista.
	var marker := aim_dir * AIM_MARKER_DISTANCE
	var color := MARKER_READY_COLOR if _technique_ready else MARKER_WAIT_COLOR
	draw_circle(marker, 0.3 if _technique_ready else 0.18, color)
	if _visual == null:
		draw_circle(Vector2(0.0, -0.9), RADIUS, BASE_COLOR)
