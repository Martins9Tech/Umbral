class_name EnemySwarm
extends Node2D
## Horda orientada a datos (TECNICO §3): arrays + rejilla espacial + MultiMesh 2D.
## Nada de nodos ni física por enemigo. Los índices son estables durante el
## frame; los muertos se retiran en flush_dead() al final del combate.
## Cada enemigo persigue al objetivo (jugador vivo) más cercano.

signal enemy_died(type_index: int, position: Vector2, flags: int)

const MAX_ENEMIES := 3000
const CELL_SIZE := 2.0
const KNOCKBACK_DECAY := 7.0
const SEPARATION_STRENGTH := 0.45
const FLASH_TIME := 0.08
const SLOW_FACTOR := 0.5
## Transformación 2D (8) + color (4) + datos propios (4: destello).
const FLOATS_PER_INSTANCE := 16
const SHADOW_FLOATS := 8
const SPRITE_DIR := "res://assets/sprites/enemigos/"
const HORDE_SHADER := preload("res://shaders/horda_2d.gdshader")

# Élites (GDD §7.4): flags combinables
const FLAG_ELITE := 1
const FLAG_FAST := 2
const FLAG_ARMORED := 4
const FLAG_EXPLOSIVE := 8
## Jefe: no se mueve solo, no recibe empuje y no se dibuja aquí (tiene su propio nodo).
const FLAG_BOSS := 16
## Heraldo: mini-jefe que anticipa una mecánica del jefe.
const FLAG_HERALD := 32
## Brote del jefe: si su temporizador llega a 0 sin morir, cura al jefe.
const FLAG_SPROUT := 64
## Muerte silenciosa: sin experiencia, sin contar y sin efectos.
const FLAG_SILENT := 128
const SPROUT_COLOR := Color(0.45, 1.0, 0.35)
const HERALD_COLOR := Color(1.0, 0.3, 0.2)
const RETREAT_SPEED_MULT := 1.6
## Está ardiendo (lo usa la sinergia de Fuego al morir).
const FLAG_BURNING := 256
## Objeto rompible del mapa: inmóvil, sin daño, se dibuja aparte.
const FLAG_PROP := 512
## Los congelados no se mueven, no hacen daño y reciben más daño.
const FROZEN_DAMAGE_MULT := 1.5
const BURN_COLOR := Color(1.0, 0.45, 0.15)
const SLOW_COLOR := Color(0.45, 0.75, 1.0)
const FROZEN_COLOR := Color(0.8, 0.95, 1.0)
const ELITE_HP_MULT := 14.0
const ELITE_SIZE := 1.6
const ELITE_DPS_MULT := 1.6
const FAST_SPEED_MULT := 1.5
const ARMORED_DAMAGE_MULT := 0.5
const ELITE_COLOR := Color(1.0, 0.78, 0.25)

var types: Array[EnemyData] = []
var bounds := Rect2()
var obstacles: Array[Vector3] = []
var grid: SpatialGrid
## Posiciones de los jugadores vivos (las rellena Run cada frame).
var targets := PackedVector2Array()
var target_radius := 0.5
## Daño por segundo que recibe cada objetivo este frame (mismo orden que targets).
var touching_dps := PackedFloat32Array()
## Multiplicador de vida al generar (lo sube el Director con el tiempo).
var hp_scale := 1.0
var slow_zones: Array[Dictionary] = []

var count := 0
## Objetos rompibles (urnas) dentro de `count`: no cuentan como horda.
var prop_count := 0
var pos := PackedVector2Array()
var knock := PackedVector2Array()
var hp := PackedFloat32Array()
var max_hp := PackedFloat32Array()
var kind := PackedInt32Array()
var flash := PackedFloat32Array()
var radius := PackedFloat32Array()
var speed := PackedFloat32Array()
var dps := PackedFloat32Array()
var damage_mult := PackedFloat32Array()
var flags := PackedInt32Array()
## Temporizador genérico por enemigo (p. ej. brotes); baja solo hasta 0.
var timer := PackedFloat32Array()
# Estados alterados
var burn_time := PackedFloat32Array()
var burn_dps := PackedFloat32Array()
var burn_owner := PackedInt32Array()
var slow_time := PackedFloat32Array()
var slow_mult := PackedFloat32Array()
var freeze_time := PackedFloat32Array()
## Desfase de la animación procedural de cada enemigo.
var anim_phase := PackedFloat32Array()
## Índice actual del jefe en los arrays (-1 si no hay). Se actualiza al compactar.
var boss_slot := -1
## Mientras sea > 0, la horda huye de los jugadores (antes del jefe).
var retreat_left := 0.0

var _dead: Array[int] = []
## Durante flush_dead no se pueden encolar índices (cambian al compactar):
## las muertes de ese momento se recogen con un repaso al final.
var _flushing := false
var _missed_deaths := false
var _obstacle_cells := PackedByteArray()
var _multimeshes: Array[MultiMesh] = []
var _buffers: Array[PackedFloat32Array] = []
var _shadow_multimesh: MultiMesh
var _shadow_buffer := PackedFloat32Array()
var _time := 0.0


func setup(p_types: Array[EnemyData], p_bounds: Rect2, p_obstacles: Array[Vector3]) -> void:
	types = p_types
	bounds = p_bounds
	obstacles = p_obstacles
	grid = SpatialGrid.new(bounds, CELL_SIZE, MAX_ENEMIES)
	pos.resize(MAX_ENEMIES)
	knock.resize(MAX_ENEMIES)
	hp.resize(MAX_ENEMIES)
	max_hp.resize(MAX_ENEMIES)
	kind.resize(MAX_ENEMIES)
	flash.resize(MAX_ENEMIES)
	radius.resize(MAX_ENEMIES)
	speed.resize(MAX_ENEMIES)
	dps.resize(MAX_ENEMIES)
	damage_mult.resize(MAX_ENEMIES)
	flags.resize(MAX_ENEMIES)
	timer.resize(MAX_ENEMIES)
	burn_time.resize(MAX_ENEMIES)
	burn_dps.resize(MAX_ENEMIES)
	burn_owner.resize(MAX_ENEMIES)
	slow_time.resize(MAX_ENEMIES)
	slow_mult.resize(MAX_ENEMIES)
	freeze_time.resize(MAX_ENEMIES)
	anim_phase.resize(MAX_ENEMIES)
	_build_obstacle_cells()
	_build_render()


## Sombras (debajo) y un MultiMesh por tipo con su dibujo; los tipos grandes
## se dibujan primero para que los pequeños queden visibles encima.
func _build_render() -> void:
	_shadow_multimesh = Draw2D.multimesh_2d(Draw2D.quad_mesh(Vector2.ONE), MAX_ENEMIES, false, false, bounds)
	var shadows := MultiMeshInstance2D.new()
	shadows.multimesh = _shadow_multimesh
	shadows.texture = Draw2D.radial_texture()
	shadows.modulate = Color(0.0, 0.0, 0.0, 0.5)
	add_child(shadows)
	_shadow_buffer.resize(MAX_ENEMIES * SHADOW_FLOATS)
	var order: Array[int] = []
	for t in types.size():
		order.append(t)
		_multimeshes.append(null)
		var buffer := PackedFloat32Array()
		buffer.resize(MAX_ENEMIES * FLOATS_PER_INSTANCE)
		_buffers.append(buffer)
	order.sort_custom(func(a: int, b: int) -> bool: return types[a].sprite_height > types[b].sprite_height)
	for t: int in order:
		var data := types[t]
		var texture := load(SPRITE_DIR + "%s.png" % data.id) as Texture2D
		var size := Vector2(data.sprite_height, data.sprite_height)
		if texture != null:
			size.x = data.sprite_height * texture.get_width() / float(texture.get_height())
		var multimesh := Draw2D.multimesh_2d(Draw2D.quad_mesh(size, Vector2(0.5, 0.96)), MAX_ENEMIES, true, true, bounds)
		var instance := MultiMeshInstance2D.new()
		instance.multimesh = multimesh
		instance.texture = texture
		var material := ShaderMaterial.new()
		material.shader = HORDE_SHADER
		instance.material = material
		add_child(instance)
		_multimeshes[t] = multimesh



## Genera un enemigo. Los parámetros *_override (>0) sustituyen a los del tipo;
## life_timer arranca su temporizador (brotes).
func spawn(type_index: int, p: Vector2, enemy_flags: int = 0, hp_override: float = -1.0,
		radius_override: float = -1.0, dps_override: float = -1.0, life_timer: float = 0.0) -> bool:
	if count >= MAX_ENEMIES:
		return false
	var data := types[type_index]
	var elite := enemy_flags & FLAG_ELITE != 0
	var i := count
	pos[i] = p.clamp(bounds.position, bounds.end)
	knock[i] = Vector2.ZERO
	var health := hp_override if hp_override > 0.0 \
		else data.max_hp * hp_scale * (ELITE_HP_MULT if elite else 1.0)
	hp[i] = health
	max_hp[i] = health
	kind[i] = type_index
	flash[i] = 0.0
	radius[i] = radius_override if radius_override > 0.0 else data.radius * (ELITE_SIZE if elite else 1.0)
	speed[i] = data.speed * (FAST_SPEED_MULT if enemy_flags & FLAG_FAST != 0 else 1.0)
	dps[i] = dps_override if dps_override > 0.0 else data.contact_dps * (ELITE_DPS_MULT if elite else 1.0)
	damage_mult[i] = ARMORED_DAMAGE_MULT if enemy_flags & FLAG_ARMORED != 0 else 1.0
	flags[i] = enemy_flags
	timer[i] = life_timer
	burn_time[i] = 0.0
	burn_dps[i] = 0.0
	burn_owner[i] = 0
	slow_time[i] = 0.0
	slow_mult[i] = 1.0
	freeze_time[i] = 0.0
	anim_phase[i] = randf() * TAU
	if enemy_flags & FLAG_BOSS:
		boss_slot = i
	if enemy_flags & FLAG_PROP:
		prop_count += 1
	count += 1
	return true


## Mata sin experiencia ni efectos (brotes absorbidos, horda que se retira).
func kill_silent(i: int) -> void:
	if i < 0 or i >= count or hp[i] <= 0.0:
		return
	flags[i] |= FLAG_SILENT
	hp[i] = 0.0
	_queue_dead(i)


## Retira en silencio a todos menos al jefe (se aplica en el siguiente flush).
func clear_all_but_boss() -> void:
	for i in count:
		if flags[i] & FLAG_BOSS == 0:
			kill_silent(i)


## Enemigos de verdad (sin urnas ni otros objetos).
func enemy_count() -> int:
	return count - prop_count


func radius_of(i: int) -> float:
	return radius[i]


func is_elite(i: int) -> bool:
	return flags[i] & FLAG_ELITE != 0


## Aplica daño. Devuelve false si el enemigo no existe o ya estaba muerto.
func damage(i: int, amount: float, knockback: Vector2 = Vector2.ZERO) -> bool:
	if i < 0 or i >= count or hp[i] <= 0.0:
		return false
	if freeze_time[i] > 0.0:
		amount *= FROZEN_DAMAGE_MULT
	hp[i] -= amount * damage_mult[i]
	flash[i] = FLASH_TIME
	if knockback != Vector2.ZERO and flags[i] & (FLAG_BOSS | FLAG_PROP) == 0:
		# Los enemigos grandes se resisten más al empuje.
		knock[i] += knockback * (0.45 / radius[i])
	if hp[i] <= 0.0:
		_queue_dead(i)
	return true


## Daño por segundo (quemaduras): sin destello ni empuje.
func damage_over_time(i: int, amount: float) -> void:
	if i < 0 or i >= count or hp[i] <= 0.0:
		return
	hp[i] -= amount * damage_mult[i]
	if hp[i] <= 0.0:
		_queue_dead(i)


# --- Estados alterados ---

func apply_burn(i: int, burn_per_second: float, duration: float, owner: int) -> void:
	if i < 0 or i >= count or hp[i] <= 0.0:
		return
	burn_dps[i] = maxf(burn_dps[i], burn_per_second)
	burn_time[i] = maxf(burn_time[i], duration)
	burn_owner[i] = owner
	flags[i] |= FLAG_BURNING


func apply_slow(i: int, mult: float, duration: float) -> void:
	if i < 0 or i >= count or flags[i] & FLAG_BOSS:
		return
	slow_mult[i] = minf(slow_mult[i] if slow_time[i] > 0.0 else 1.0, mult)
	slow_time[i] = maxf(slow_time[i], duration)


## Congela (o aturde): los jefes son inmunes, los élites lo sufren la mitad.
func apply_freeze(i: int, duration: float) -> void:
	if i < 0 or i >= count or flags[i] & FLAG_BOSS:
		return
	var final_duration := duration * (0.5 if flags[i] & FLAG_ELITE else 1.0)
	freeze_time[i] = maxf(freeze_time[i], final_duration)


func _queue_dead(i: int) -> void:
	if _flushing:
		_missed_deaths = true
	else:
		_dead.append(i)


func add_slow_zone(a: Vector2, b: Vector2, width: float, duration: float) -> void:
	slow_zones.append({"a": a, "b": b, "width": width, "time": duration})


func simulate(delta: float) -> void:
	_time += delta
	_tick_slow_zones(delta)
	grid.rebuild(pos, count)
	var n_targets := targets.size()
	touching_dps.resize(n_targets)
	touching_dps.fill(0.0)
	var head := grid.head
	var next_index := grid.next_index
	var grid_w := grid.width
	var grid_h := grid.height
	var origin_x := grid.origin.x
	var origin_y := grid.origin.y
	var inv_cell := 1.0 / CELL_SIZE
	var min_p := bounds.position
	var max_p := bounds.end
	var has_zones := not slow_zones.is_empty()
	var decay := maxf(0.0, 1.0 - KNOCKBACK_DECAY * delta)
	var retreating := retreat_left > 0.0
	retreat_left = maxf(0.0, retreat_left - delta)

	for i in count:
		var p := pos[i]
		var r := radius[i]
		if timer[i] > 0.0:
			timer[i] = maxf(0.0, timer[i] - delta)
		if flags[i] & FLAG_PROP:
			if flash[i] > 0.0:
				flash[i] -= delta
			continue
		if flags[i] & FLAG_BOSS:
			# El jefe lo mueve su controlador; aquí solo cuenta el contacto.
			for t in n_targets:
				if p.distance_to(targets[t]) < r + target_radius:
					touching_dps[t] += dps[i]
			if flash[i] > 0.0:
				flash[i] -= delta
			continue
		var move := Vector2.ZERO
		var frozen := freeze_time[i] > 0.0
		if frozen:
			freeze_time[i] = maxf(0.0, freeze_time[i] - delta)
		if slow_time[i] > 0.0:
			slow_time[i] = maxf(0.0, slow_time[i] - delta)
		if n_targets > 0 and not frozen:
			# Objetivo: el jugador vivo más cercano.
			var best := 0
			var best_d2 := INF
			for t in n_targets:
				var d2_target := p.distance_squared_to(targets[t])
				if d2_target < best_d2:
					best_d2 = d2_target
					best = t
			var to_target := targets[best] - p
			var dist := sqrt(best_d2)
			var move_speed := speed[i]
			if slow_time[i] > 0.0:
				move_speed *= slow_mult[i]
			if has_zones and _in_slow_zone(p):
				move_speed *= SLOW_FACTOR
			if retreating:
				if dist > 0.0001:
					move = -to_target * (move_speed * RETREAT_SPEED_MULT / dist)
			elif dist < r + target_radius:
				touching_dps[best] += dps[i]
			elif dist > 0.0001:
				move = to_target * (move_speed / dist)

		# Separación con los vecinos de las 3×3 celdas cercanas.
		var sep := Vector2.ZERO
		var cx := clampi(int((p.x - origin_x) * inv_cell), 0, grid_w - 1)
		var cy := clampi(int((p.y - origin_y) * inv_cell), 0, grid_h - 1)
		for gy in range(maxi(cy - 1, 0), mini(cy + 2, grid_h)):
			var row := gy * grid_w
			for gx in range(maxi(cx - 1, 0), mini(cx + 2, grid_w)):
				var j := head[row + gx]
				while j != -1:
					if j != i:
						var d := p - pos[j]
						var min_dist := r + radius[j]
						var d2 := d.length_squared()
						if d2 < min_dist * min_dist and d2 > 0.000001:
							var dl := sqrt(d2)
							sep += d * ((min_dist - dl) / dl)
					j = next_index[j]

		var k := knock[i]
		p += (move + k) * delta + sep * SEPARATION_STRENGTH
		knock[i] = k * decay
		if _obstacle_cells[cy * grid_w + cx] == 1:
			p = _push_out_of_obstacles(p, r)
		pos[i] = p.clamp(min_p, max_p)
		if flash[i] > 0.0:
			flash[i] -= delta


## Retira los enemigos muertos este frame (swap-remove) y emite enemy_died.
func flush_dead() -> void:
	_flushing = true
	while not _dead.is_empty():
		_flush_pass()
		if _missed_deaths:
			_missed_deaths = false
			for i in count:
				if hp[i] <= 0.0:
					_dead.append(i)
	_flushing = false


func _flush_pass() -> void:
	_dead.sort()
	for k in range(_dead.size() - 1, -1, -1):
		var i := _dead[k]
		enemy_died.emit(kind[i], pos[i], flags[i])
		if flags[i] & FLAG_PROP:
			prop_count -= 1
		if i == boss_slot:
			boss_slot = -1
		var last := count - 1
		if i != last:
			if last == boss_slot:
				boss_slot = i
			timer[i] = timer[last]
			burn_time[i] = burn_time[last]
			burn_dps[i] = burn_dps[last]
			burn_owner[i] = burn_owner[last]
			slow_time[i] = slow_time[last]
			slow_mult[i] = slow_mult[last]
			freeze_time[i] = freeze_time[last]
			anim_phase[i] = anim_phase[last]
			pos[i] = pos[last]
			knock[i] = knock[last]
			hp[i] = hp[last]
			max_hp[i] = max_hp[last]
			kind[i] = kind[last]
			flash[i] = flash[last]
			radius[i] = radius[last]
			speed[i] = speed[last]
			dps[i] = dps[last]
			damage_mult[i] = damage_mult[last]
			flags[i] = flags[last]
		count -= 1
	_dead.clear()


## Dibujo: cada enemigo mira hacia su objetivo y se anima por código según su
## tipo (salta, galopa o se balancea). Los estados tiñen el dibujo y el daño
## lo hace destellar en blanco.
func render() -> void:
	var glow := 0.35 + 0.25 * sin(_time * 6.0)
	var look_at := targets[0] if targets.size() > 0 else Vector2.ZERO
	var shadows := 0
	for i in count:
		if flags[i] & (FLAG_PROP | FLAG_BOSS):
			continue
		var r := radius[i]
		Draw2D.write_xform(_shadow_buffer, shadows * SHADOW_FLOATS, pos[i], 0.0, r * 2.8, r * 1.1)
		shadows += 1
	_shadow_multimesh.buffer = _shadow_buffer
	_shadow_multimesh.visible_instance_count = shadows

	for t in types.size():
		# Se saca el buffer del array para escribirlo sin copias (copy-on-write).
		var buffer: PackedFloat32Array = _buffers[t]
		_buffers[t] = PackedFloat32Array()
		var data := types[t]
		var anim := data.anim
		var freq := 7.5 if anim == &"salto" else (13.0 if anim == &"galope" else 3.4)
		var n := 0
		for i in count:
			if kind[i] != t or flags[i] & (FLAG_BOSS | FLAG_PROP):
				continue
			var p := pos[i]
			var size := radius[i] / data.radius
			var phase := anim_phase[i]
			var frozen := freeze_time[i] > 0.0
			var wave := phase if frozen else _time * freq + phase
			var s := sin(wave)
			var lift := 0.0
			var rot := 0.0
			var sx := size
			var sy := size
			match anim:
				&"salto":
					var f := absf(s)
					var squash := 1.0 - smoothstep(0.0, 0.25, f)
					lift = f * 0.28 * size
					sx *= 1.0 + 0.16 * squash
					sy *= 1.0 - 0.14 * squash + 0.05 * f
				&"galope":
					rot = s * 0.09
					lift = absf(s) * 0.12 * size
					sy *= 1.0 - 0.04 * sin(wave * 2.0)
				_:
					rot = s * 0.08
					lift = absf(s) * 0.09 * size
			if look_at.x < p.x:
				sx = -sx
				rot = -rot
			var b := n * FLOATS_PER_INSTANCE
			Draw2D.write_xform(buffer, b, Vector2(p.x, p.y - lift), rot, sx, sy)
			var c := Color.WHITE
			if frozen:
				c = Color.WHITE.lerp(FROZEN_COLOR, 0.75)
			elif burn_time[i] > 0.0:
				c = Color.WHITE.lerp(BURN_COLOR, 0.45 + 0.2 * glow)
			elif slow_time[i] > 0.0:
				c = Color.WHITE.lerp(SLOW_COLOR, 0.5)
			elif flags[i] & FLAG_SPROUT:
				c = Color.WHITE.lerp(SPROUT_COLOR, 0.5 + glow)
			elif flags[i] & FLAG_HERALD:
				c = Color.WHITE.lerp(HERALD_COLOR, 0.4 + glow)
			elif flags[i] & FLAG_ELITE:
				c = Color.WHITE.lerp(ELITE_COLOR, 0.35 + glow)
			buffer[b + 8] = c.r
			buffer[b + 9] = c.g
			buffer[b + 10] = c.b
			buffer[b + 11] = 1.0
			buffer[b + 12] = 1.0 if flash[i] > 0.0 else 0.0
			buffer[b + 13] = 0.0
			buffer[b + 14] = 0.0
			buffer[b + 15] = 0.0
			n += 1
		var multimesh := _multimeshes[t]
		multimesh.buffer = buffer
		multimesh.visible_instance_count = n
		_buffers[t] = buffer


func _tick_slow_zones(delta: float) -> void:
	for k in range(slow_zones.size() - 1, -1, -1):
		var zone := slow_zones[k]
		var time_left: float = zone["time"]
		time_left -= delta
		zone["time"] = time_left
		if time_left <= 0.0:
			slow_zones.remove_at(k)


func _in_slow_zone(p: Vector2) -> bool:
	for zone: Dictionary in slow_zones:
		var a: Vector2 = zone["a"]
		var b: Vector2 = zone["b"]
		var width: float = zone["width"]
		if Geometry2D.get_closest_point_to_segment(p, a, b).distance_squared_to(p) < width * width:
			return true
	return false


func _push_out_of_obstacles(p: Vector2, r: float) -> Vector2:
	for o: Vector3 in obstacles:
		var center := Vector2(o.x, o.y)
		var offset := p - center
		var min_dist := o.z + r
		if offset.length_squared() < min_dist * min_dist:
			p = center + offset.normalized() * min_dist
	return p


## Marca las celdas cercanas a obstáculos para no comprobarlos en todas.
func _build_obstacle_cells() -> void:
	_obstacle_cells.resize(grid.width * grid.height)
	_obstacle_cells.fill(0)
	var margin := CELL_SIZE * 1.5 + 1.5
	for cy in grid.height:
		for cx in grid.width:
			var center := grid.origin + Vector2((cx + 0.5) * CELL_SIZE, (cy + 0.5) * CELL_SIZE)
			for o: Vector3 in obstacles:
				if center.distance_to(Vector2(o.x, o.y)) < o.z + margin:
					_obstacle_cells[cy * grid.width + cx] = 1
					break
