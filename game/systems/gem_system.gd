class_name GemSystem
extends Node2D
## Objetos recogibles orientados a datos + MultiMesh: gemas de experiencia,
## oro y objetos (comida, imán, bomba). Las gemas y el oro los atrae el imán;
## los objetos hay que tocarlos. Si se llena, la experiencia se fusiona.

enum Kind { XP, GOLD, FOOD, MAGNET, BOMB }

const MAX_GEMS := 800
## Transformación 2D (8) + color (4).
const FLOATS_PER_INSTANCE := 12
const COLLECT_RADIUS := 0.7
const ITEM_TOUCH_RADIUS := 1.2
const ATTRACT_START_SPEED := 8.0
const ATTRACT_ACCELERATION := 45.0
const GOLD_COLOR := Color(1.0, 0.82, 0.2)
const ITEM_COLORS := {
	Kind.FOOD: Color(1.0, 0.35, 0.4),
	Kind.MAGNET: Color(0.35, 0.55, 1.0),
	Kind.BOMB: Color(0.25, 0.08, 0.08),
}

var count := 0
var pos := PackedVector2Array()
var value := PackedInt32Array()
var kind := PackedByteArray()
var speed := PackedFloat32Array()
var attracted := PackedByteArray()
## Objetos no-experiencia recogidos en la última llamada a simulate: (tipo, valor).
var last_pickups: Array[Vector2i] = []

var _multimesh: MultiMesh
var _buffer := PackedFloat32Array()
var _rng := RandomNumberGenerator.new()
var _time := 0.0


func setup(bounds: Rect2) -> void:
	pos.resize(MAX_GEMS)
	value.resize(MAX_GEMS)
	kind.resize(MAX_GEMS)
	speed.resize(MAX_GEMS)
	attracted.resize(MAX_GEMS)

	# Rombo con brillo (textura de disco suave recortada en rombo por la malla).
	var mesh := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector2Array([Vector2(0, -0.28), Vector2(0.2, 0), Vector2(0, 0.28), Vector2(-0.2, 0)])
	arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array([Vector2(0.5, 0.0), Vector2(1.0, 0.5), Vector2(0.5, 1.0), Vector2(0.0, 0.5)])
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2, 0, 2, 3])
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	_multimesh = Draw2D.multimesh_2d(mesh, MAX_GEMS, true, false, bounds)
	var instance := MultiMeshInstance2D.new()
	instance.multimesh = _multimesh
	add_child(instance)
	_buffer.resize(MAX_GEMS * FLOATS_PER_INSTANCE)


func spawn(p: Vector2, amount: int, pickup_kind: Kind = Kind.XP) -> void:
	if count >= MAX_GEMS:
		if pickup_kind == Kind.XP:
			value[_rng.randi_range(0, count - 1)] += amount
		return
	pos[count] = p
	value[count] = amount
	kind[count] = pickup_kind
	speed[count] = 0.0
	attracted[count] = 0
	count += 1


## Mueve lo atraído y devuelve la experiencia recogida; el resto de objetos
## recogidos quedan en last_pickups.
func simulate(delta: float, player_pos: Vector2, magnet_radius: float) -> int:
	last_pickups.clear()
	var gained := 0
	var magnet_sq := magnet_radius * magnet_radius
	var touch_sq := ITEM_TOUCH_RADIUS * ITEM_TOUCH_RADIUS
	var collect_sq := COLLECT_RADIUS * COLLECT_RADIUS
	var i := 0
	while i < count:
		var p := pos[i]
		var to_player := player_pos - p
		var dist_sq := to_player.length_squared()
		var k := kind[i]
		if k >= Kind.FOOD:
			# Los objetos se recogen al tocarlos (no los atrae el imán).
			if dist_sq < touch_sq:
				last_pickups.append(Vector2i(k, value[i]))
				_remove(i)
				continue
			i += 1
			continue
		if attracted[i] == 0 and dist_sq < magnet_sq:
			attracted[i] = 1
			speed[i] = ATTRACT_START_SPEED
		if attracted[i] == 1:
			if dist_sq < collect_sq:
				if k == Kind.XP:
					gained += value[i]
				else:
					last_pickups.append(Vector2i(k, value[i]))
				_remove(i)
				continue
			var s := speed[i] + ATTRACT_ACCELERATION * delta
			speed[i] = s
			var dist := sqrt(dist_sq)
			pos[i] = p + to_player / dist * minf(s * delta, dist)
		i += 1
	return gained


## Atrae toda la experiencia y el oro del mapa (objeto "imán").
func attract_all() -> void:
	for i in count:
		if kind[i] <= Kind.GOLD:
			attracted[i] = 1
			speed[i] = ATTRACT_START_SPEED


func render(delta: float = 0.0) -> void:
	_time += delta
	for i in count:
		var b := i * FLOATS_PER_INSTANCE
		var p := pos[i]
		var k := kind[i]
		var c := Color("3fd46a")  # esmeralda (GUIA_ESTILO §3)
		var size := 1.0
		var lift := 0.25 + 0.06 * sin(_time * 4.0 + p.x)
		match k:
			Kind.XP:
				var v := value[i]
				if v >= 20:
					c = Color("ffae3d")
					size = 1.35
				elif v >= 5:
					c = Color("b5ff5a")
					size = 1.15
			Kind.GOLD:
				c = GOLD_COLOR
				size = 1.15
			_:
				c = ITEM_COLORS[k]
				size = 2.4
				lift = 0.6 + 0.15 * sin(_time * 4.0)
		Draw2D.write_xform(_buffer, b, Vector2(p.x, p.y - lift), 0.0, size, size)
		_buffer[b + 8] = c.r
		_buffer[b + 9] = c.g
		_buffer[b + 10] = c.b
		_buffer[b + 11] = 1.0
	_multimesh.buffer = _buffer
	_multimesh.visible_instance_count = count


func item_positions() -> Array[Vector3]:
	## (x, z, tipo) de los objetos que no son experiencia ni oro.
	var out: Array[Vector3] = []
	for i in count:
		if kind[i] >= Kind.FOOD:
			out.append(Vector3(pos[i].x, pos[i].y, kind[i]))
	return out


func _remove(i: int) -> void:
	var last := count - 1
	if i != last:
		pos[i] = pos[last]
		value[i] = value[last]
		kind[i] = kind[last]
		speed[i] = speed[last]
		attracted[i] = attracted[last]
	count -= 1
