class_name ProjectileSystem
extends Node2D
## Proyectiles orientados a datos + MultiMesh 2D (TECNICO §4.6): esferas de luz
## con mezcla aditiva, a media altura del cuerpo.

const MAX_PROJECTILES := 2500
## Transformación 2D (8) + color (4).
const FLOATS_PER_INSTANCE := 12
const HEIGHT := 0.8

var bounds := Rect2()
var count := 0
var pos := PackedVector2Array()
var vel := PackedVector2Array()
var damage := PackedFloat32Array()
var radius := PackedFloat32Array()
var life := PackedFloat32Array()
var knockback := PackedFloat32Array()
var pierce := PackedInt32Array()
var last_hit := PackedInt32Array()
var source := PackedInt32Array()
var color := PackedColorArray()
## Índice del jugador que lo disparó (para atribuir el daño).
var owner_index := PackedInt32Array()

var _sources: Array[StringName] = []
var _multimesh: MultiMesh
var _buffer := PackedFloat32Array()


func setup(p_bounds: Rect2) -> void:
	bounds = p_bounds
	pos.resize(MAX_PROJECTILES)
	vel.resize(MAX_PROJECTILES)
	damage.resize(MAX_PROJECTILES)
	radius.resize(MAX_PROJECTILES)
	life.resize(MAX_PROJECTILES)
	knockback.resize(MAX_PROJECTILES)
	pierce.resize(MAX_PROJECTILES)
	last_hit.resize(MAX_PROJECTILES)
	source.resize(MAX_PROJECTILES)
	color.resize(MAX_PROJECTILES)
	owner_index.resize(MAX_PROJECTILES)

	_multimesh = Draw2D.multimesh_2d(Draw2D.quad_mesh(Vector2.ONE), MAX_PROJECTILES, true, false, bounds)
	var instance := MultiMeshInstance2D.new()
	instance.multimesh = _multimesh
	instance.texture = Draw2D.soft_disc_texture()
	var material := CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	instance.material = material
	add_child(instance)
	_buffer.resize(MAX_PROJECTILES * FLOATS_PER_INSTANCE)


func spawn(p: Vector2, velocity: Vector2, amount: float, hit_radius: float, lifetime: float,
		p_pierce: int, source_id: StringName, tint: Color, shooter: int, knock: float = 2.0) -> void:
	if count >= MAX_PROJECTILES:
		return
	var i := count
	pos[i] = p
	vel[i] = velocity
	damage[i] = amount
	radius[i] = hit_radius
	life[i] = lifetime
	knockback[i] = knock
	pierce[i] = p_pierce
	last_hit[i] = -1
	source[i] = _source_index(source_id)
	color[i] = tint
	owner_index[i] = shooter
	count += 1


func simulate(delta: float, run: Run) -> void:
	var swarm := run.swarm
	var i := 0
	while i < count:
		life[i] -= delta
		var p := pos[i] + vel[i] * delta
		pos[i] = p
		if life[i] <= 0.0 or not bounds.has_point(p):
			_remove(i)
			continue
		var r := radius[i]
		var spent := false
		for e: int in swarm.grid.query(p, r + Run.MAX_ENEMY_RADIUS):
			if e == last_hit[i] or not run.is_valid_target(e):
				continue
			var reach := r + swarm.radius_of(e)
			if p.distance_squared_to(swarm.pos[e]) > reach * reach:
				continue
			run.hit_enemy(e, damage[i], _sources[source[i]], vel[i].normalized() * knockback[i],
				run.players[owner_index[i]])
			last_hit[i] = e
			pierce[i] -= 1
			if pierce[i] < 0:
				spent = true
				break
		if spent:
			_remove(i)
			continue
		i += 1


func render() -> void:
	for i in count:
		var b := i * FLOATS_PER_INSTANCE
		var size := radius[i] * 2.6
		var p := pos[i]
		var c := color[i]
		Draw2D.write_xform(_buffer, b, Vector2(p.x, p.y - HEIGHT), 0.0, size, size)
		_buffer[b + 8] = c.r
		_buffer[b + 9] = c.g
		_buffer[b + 10] = c.b
		_buffer[b + 11] = c.a
	_multimesh.buffer = _buffer
	_multimesh.visible_instance_count = count


func _source_index(source_id: StringName) -> int:
	var index := _sources.find(source_id)
	if index < 0:
		_sources.append(source_id)
		index = _sources.size() - 1
	return index


func _remove(i: int) -> void:
	var last := count - 1
	if i != last:
		pos[i] = pos[last]
		vel[i] = vel[last]
		damage[i] = damage[last]
		radius[i] = radius[last]
		life[i] = life[last]
		knockback[i] = knockback[last]
		pierce[i] = pierce[last]
		last_hit[i] = last_hit[last]
		source[i] = source[last]
		color[i] = color[last]
		owner_index[i] = owner_index[last]
	count -= 1
