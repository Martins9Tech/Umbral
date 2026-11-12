class_name SpatialGrid
extends RefCounted
## Rejilla espacial uniforme (listas enlazadas por celda) para consultas de
## vecinos sin física (TECNICO §3). Se reconstruye entera cada frame.

var cell_size: float
var origin: Vector2
var width: int
var height: int
## Primer índice de cada celda (-1 si está vacía).
var head := PackedInt32Array()
## Siguiente índice de la misma celda (-1 al final).
var next_index := PackedInt32Array()


func _init(bounds: Rect2, p_cell_size: float, capacity: int) -> void:
	cell_size = p_cell_size
	origin = bounds.position
	width = int(ceil(bounds.size.x / cell_size)) + 1
	height = int(ceil(bounds.size.y / cell_size)) + 1
	head.resize(width * height)
	head.fill(-1)
	next_index.resize(capacity)


func cell_x(x: float) -> int:
	return clampi(int((x - origin.x) / cell_size), 0, width - 1)


func cell_y(y: float) -> int:
	return clampi(int((y - origin.y) / cell_size), 0, height - 1)


func rebuild(positions: PackedVector2Array, count: int) -> void:
	head.fill(-1)
	for i in count:
		var p := positions[i]
		var cell := cell_y(p.y) * width + cell_x(p.x)
		next_index[i] = head[cell]
		head[cell] = i


## Devuelve los índices de las celdas que cubren el círculo (candidatos;
## quien llama comprueba la distancia exacta).
func query(center: Vector2, radius: float) -> PackedInt32Array:
	var out := PackedInt32Array()
	var x0 := cell_x(center.x - radius)
	var x1 := cell_x(center.x + radius)
	var y0 := cell_y(center.y - radius)
	var y1 := cell_y(center.y + radius)
	for cy in range(y0, y1 + 1):
		var row := cy * width
		for cx in range(x0, x1 + 1):
			var j := head[row + cx]
			while j != -1:
				out.append(j)
				j = next_index[j]
	return out
