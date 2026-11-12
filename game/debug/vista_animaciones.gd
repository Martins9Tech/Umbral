extends Node2D
## Vista previa de las animaciones de la marioneta (para revisarlas con capturas):
## godot --path . res://debug/vista_animaciones.tscn --fixed-fps 30 --write-movie out.png
## Secuencia: quieto, andar, puñetazo, gancho, zancada, paso, golpe de tierra, muerte.

const SECUENCIA := [
	[&"quieto", 0.6], [&"andar", 1.4], [&"punetazo", 0.6], [&"punetazo", 0.6],
	[&"zancada", 0.6], [&"paso", 0.5], [&"golpe_tierra", 1.0], [&"morir", 1.2],
]

var _m: MarionetaOrrun
var _paso := -1
var _t := 0.0


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.18, 0.15, 0.13))
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_m = MarionetaOrrun.new()
	_m.position = Vector2(960, 900)
	add_child(_m)
	_m.scale = Vector2.ONE * 700.0 / _m.altura
	_m.capa_fantasmas = self
	_siguiente()


func _process(delta: float) -> void:
	_t -= delta
	if _t <= 0.0:
		_siguiente()


func _siguiente() -> void:
	_paso += 1
	if _paso >= SECUENCIA.size():
		get_tree().quit()
		return
	var nombre: StringName = SECUENCIA[_paso][0]
	_t = SECUENCIA[_paso][1]
	_m.movimiento = 1.0 if nombre == &"andar" else 0.0
	match nombre:
		&"quieto", &"andar":
			pass
		&"morir":
			_m.morir()
		_:
			_m.accion(nombre)
