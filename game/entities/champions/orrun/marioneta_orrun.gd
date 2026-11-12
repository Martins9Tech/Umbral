class_name MarionetaOrrun
extends Node2D
## Orrun en 2D: marioneta recortada del dibujo entero (tools/sprites/despiezar.py),
## así conserva sus proporciones. Las piezas y sus articulaciones vienen de
## `rig.json`; las animaciones se hacen por código:
## quieto, andar, puñetazo (dos variantes), zancada, paso, golpe de tierra,
## golpe recibido y muerte.
## El origen del nodo está a los pies. Mira a la derecha; se voltea con `facing`.
## Mide `altura` unidades: quien lo usa lo escala (Player, a metros).
##
## Convenio de ángulos (mirando a la derecha): un brazo o pierna con ángulo
## NEGATIVO va hacia delante; el torso con ángulo POSITIVO se inclina hacia delante.

## Golpe que conecta (puñetazo, golpe de tierra, fin de la zancada) y dónde (global).
signal impacto(accion: StringName, donde: Vector2)
## Un pie toca el suelo al andar (global).
signal pisada(donde: Vector2)

const DIR := "res://assets/sprites/orrun/"
const ACCIONES := {
	# duración, momento del impacto (fracción; -1 = sin impacto)
	&"punetazo": [0.44, 0.32],
	&"martillo": [0.5, 0.4],
	&"golpe_tierra": [0.8, 0.52],
	&"zancada": [0.42, 0.62],
	&"paso": [0.34, -1.0],
}
const HITSTOP := 0.07

var modo_entero := false
var facing := 1.0
## 0 = quieto, 1 = andando a velocidad normal.
var movimiento := 0.0
## Si es false, el dueño llama a avanzar(delta) en vez de _process.
var auto_avanzar := true
## Color base (piedra del Rasgo, invulnerable...); los destellos van encima.
var tinte := Color.WHITE
## Capa (en el mundo) donde dejar las estelas de la zancada y el paso.
var capa_fantasmas: Node2D
## Altura del dibujo en unidades locales (de los pies a la cabeza).
var altura := 600.0

var _rig: Dictionary = {}
var _sprites := {}
var _orden: Array = []
var _raiz: Node2D
var _cuerpo: Node2D
var _piezas: Node2D
var _entero: Sprite2D
var _u := 6.0  # 1 % de la altura
var _t := 0.0
var _fase := 0.0
var _accion: StringName = &""
var _accion_t := 0.0
var _impacto_hecho := false
var _hitstop := 0.0
var _variante := 0
var _flash := 0.0
var _flash_color := Color.WHITE
var _retroceso := 0.0
var _fantasma_t := 0.0
var _ultima_pisada := 0
var _muerto := false
var _muerte_t := 0.0


func _ready() -> void:
	_raiz = Node2D.new()
	add_child(_raiz)
	_cuerpo = Node2D.new()
	_raiz.add_child(_cuerpo)
	_piezas = Node2D.new()
	_cuerpo.add_child(_piezas)
	_rig = JSON.parse_string(FileAccess.get_file_as_string(DIR + "marioneta/rig.json"))
	altura = float(_rig["altura"])
	_u = altura / 100.0
	_orden = _rig["orden"]
	for nombre: String in _orden:
		var pieza: Dictionary = _rig["piezas"][nombre]
		var sprite := Sprite2D.new()
		sprite.texture = load(DIR + "marioneta/%s.png" % nombre)
		sprite.centered = false
		sprite.offset = -_v(pieza["pivote"])
		if pieza["lejana"]:
			sprite.self_modulate = Color(0.8, 0.76, 0.74)
		_piezas.add_child(sprite)
		_sprites[nombre] = sprite

	_entero = Sprite2D.new()
	_entero.texture = load(DIR + "completo.png")
	_entero.centered = false
	var tam := _entero.texture.get_size()
	_entero.offset = -Vector2(0.5 * tam.x, 0.97 * tam.y)
	_entero.scale = Vector2.ONE * altura / (0.97 * tam.y)
	_cuerpo.add_child(_entero)
	_aplicar_modo()


func cambiar_modo() -> void:
	modo_entero = not modo_entero
	_aplicar_modo()


func _aplicar_modo() -> void:
	_piezas.visible = not modo_entero
	_entero.visible = modo_entero


func ocupado() -> bool:
	return _accion != &""


## Acción puntual. El puñetazo alterna entre un directo con el brazo del lado
## al que mira y un martillazo desde arriba con el guantelete grande.
func accion(nombre: StringName) -> void:
	if _muerto:
		return
	if nombre == &"punetazo":
		_variante = 1 - _variante
		if _variante == 1:
			nombre = &"martillo"
	_accion = nombre
	_accion_t = 0.0
	_impacto_hecho = false
	_fantasma_t = 0.0


func herido() -> void:
	_flash = 0.12
	_flash_color = Color(1.6, 0.7, 0.6)
	_retroceso = 1.0


## Caída al morir (hacia atrás) y se apaga un poco.
func morir() -> void:
	_muerto = true
	_muerte_t = 0.0
	_accion = &""


func _process(delta: float) -> void:
	if auto_avanzar:
		avanzar(delta)


func avanzar(delta: float) -> void:
	_t += delta
	_raiz.scale.x = facing
	_flash = maxf(0.0, _flash - delta)
	_retroceso = maxf(0.0, _retroceso - delta * 7.0)
	if _hitstop > 0.0:
		# Congelado un instante al conectar el golpe: da peso al impacto.
		_hitstop -= delta
		modulate = _flash_color if _flash > 0.0 else tinte
		return
	var pose := _pose_base(delta)
	if _muerto:
		_pose_muerte(pose, delta)
	elif _accion != &"":
		var datos: Array = ACCIONES[_accion]
		_accion_t += delta
		var k := _accion_t / float(datos[0])
		if not _impacto_hecho and float(datos[1]) >= 0.0 and k >= float(datos[1]):
			_impacto_hecho = true
			_hitstop = HITSTOP if _accion != &"zancada" else 0.0
			_flash = 0.1
			_flash_color = Color(1.35, 1.2, 1.0)
			impacto.emit(_accion, _punto_impacto())
		if k >= 1.0:
			_accion = &""
		else:
			_pose_accion(pose, k, delta)
	modulate = _flash_color if _flash > 0.0 else tinte
	_aplicar_pose(pose)


# --- Poses ---

func _pose_base(delta: float) -> Dictionary:
	var pose := {&"torso_y": 0.0, &"torso_rot": 0.0, &"cuerpo_x": 0.0, &"cuerpo_rot": 0.0,
		&"lift": 0.0, &"estirar": 1.0}
	var andar := clampf(movimiento, 0.0, 1.3)
	var quieto := 1.0 - clampf(andar, 0.0, 1.0)
	_fase += delta * 7.0 * andar
	# Respirar.
	var respiro := sin(_t * 1.8)
	pose[&"torso_y"] = respiro * 0.6 * _u * quieto
	pose[&"torso_rot"] = 0.01 * sin(_t * 0.9) * quieto
	pose[&"brazo_del"] = 0.025 * respiro * quieto
	pose[&"brazo_tras"] = -0.025 * respiro * quieto
	pose[&"estirar"] = 1.0 + 0.008 * respiro * quieto
	if andar > 0.01:
		# Paso pesado: el cuerpo baja al apoyar, cambia el peso de lado y los
		# brazos se balancean poco y con retraso.
		var s := sin(_fase)
		var c := cos(_fase)
		var a := clampf(andar, 0.0, 1.0)
		pose[&"muslo_del"] = 0.3 * s * a
		pose[&"muslo_tras"] = -0.3 * s * a
		pose[&"pierna_del"] = 0.42 * maxf(0.0, -c) * a
		pose[&"pierna_tras"] = 0.42 * maxf(0.0, c) * a
		var arrastre := sin(_fase - 0.5)
		pose[&"brazo_del"] = -0.13 * arrastre * a
		pose[&"brazo_tras"] = 0.13 * arrastre * a
		pose[&"antebrazo_del"] = -0.08 * a - 0.06 * arrastre * a
		pose[&"antebrazo_tras"] = -0.08 * a + 0.06 * arrastre * a
		pose[&"torso_y"] += -(0.5 + 0.5 * cos(2.0 * _fase)) * 1.6 * _u * a
		pose[&"torso_rot"] = 0.05 * a + 0.035 * s * a
		pose[&"cuerpo_rot"] = 0.02 * s * a
		# Pisadas: cuando una pierna llega al tope.
		var lado := 1 if s > 0.0 else -1
		if absf(s) > 0.97 and lado != _ultima_pisada:
			_ultima_pisada = lado
			var pie := "pierna_del" if lado > 0 else "pierna_tras"
			pisada.emit(_punto_de(pie, Vector2(0.5, 0.95)))
	# Golpe recibido: se echa hacia atrás un instante.
	pose[&"torso_rot"] -= 0.12 * _retroceso
	return pose


func _pose_accion(pose: Dictionary, k: float, delta: float) -> void:
	match _accion:
		&"punetazo":
			# Directo: recoge el puño junto al hombro y lo dispara recto hacia
			# delante, con todo el cuerpo detrás (zancada y torso inclinado).
			pose[&"brazo_tras"] = _claves(k, [[0.0, 0.0], [0.26, 0.9], [0.32, -1.62], [0.62, -1.55], [1.0, 0.0]])
			pose[&"antebrazo_tras"] = _claves(k, [[0.0, 0.0], [0.26, -1.25], [0.32, -0.05], [0.62, 0.0], [1.0, 0.0]])
			pose[&"brazo_del"] = _claves(k, [[0.0, 0.0], [0.26, -0.5], [0.32, 0.55], [1.0, 0.0]])
			pose[&"antebrazo_del"] = _claves(k, [[0.0, 0.0], [0.32, -0.4], [1.0, 0.0]])
			pose[&"torso_rot"] += _claves(k, [[0.0, 0.0], [0.26, -0.12], [0.32, 0.2], [0.62, 0.16], [1.0, 0.0]])
			pose[&"cuerpo_x"] = _claves(k, [[0.0, 0.0], [0.26, -2.0 * _u], [0.32, 7.0 * _u], [0.62, 6.0 * _u], [1.0, 0.0]])
			pose[&"estirar"] = _claves(k, [[0.0, 1.0], [0.26, 0.94], [0.32, 1.05], [0.6, 1.0], [1.0, 1.0]])
			pose[&"muslo_del"] = _claves(k, [[0.0, 0.0], [0.32, 0.32], [0.62, 0.32], [1.0, 0.0]])
			pose[&"pierna_del"] = _claves(k, [[0.0, 0.0], [0.32, 0.2], [0.62, 0.2], [1.0, 0.0]])
			pose[&"muslo_tras"] = _claves(k, [[0.0, 0.0], [0.32, -0.3], [0.62, -0.3], [1.0, 0.0]])
		&"martillo":
			# Martillazo: el guantelete grande sube por detrás, pasa por encima de
			# la cabeza y cae delante con el cuerpo agachándose.
			pose[&"brazo_del"] = _claves(k, [[0.0, 0.0], [0.3, 3.1], [0.4, 5.15], [0.66, 5.1], [1.0, 0.0]])
			pose[&"antebrazo_del"] = _claves(k, [[0.0, 0.0], [0.3, 0.6], [0.4, 0.05], [1.0, 0.0]])
			pose[&"brazo_tras"] = _claves(k, [[0.0, 0.0], [0.3, -0.6], [0.4, 0.35], [1.0, 0.0]])
			pose[&"torso_rot"] += _claves(k, [[0.0, 0.0], [0.3, -0.12], [0.4, 0.28], [0.66, 0.24], [1.0, 0.0]])
			pose[&"torso_y"] += _claves(k, [[0.0, 0.0], [0.3, -3.0 * _u], [0.4, 2.0 * _u], [0.66, 1.5 * _u], [1.0, 0.0]])
			pose[&"cuerpo_x"] = _claves(k, [[0.0, 0.0], [0.4, 4.0 * _u], [0.66, 3.5 * _u], [1.0, 0.0]])
			pose[&"estirar"] = _claves(k, [[0.0, 1.0], [0.3, 1.06], [0.4, 0.88], [0.6, 0.95], [1.0, 1.0]])
			pose[&"muslo_del"] = _claves(k, [[0.0, 0.0], [0.4, 0.25], [0.66, 0.25], [1.0, 0.0]])
			pose[&"muslo_tras"] = _claves(k, [[0.0, 0.0], [0.4, -0.25], [0.66, -0.25], [1.0, 0.0]])
		&"golpe_tierra":
			# Los dos brazos por encima de la cabeza y al suelo con todo el peso.
			pose[&"brazo_del"] = _claves(k, [[0.0, 0.0], [0.38, 3.05], [0.52, 5.35], [0.8, 5.25], [1.0, 0.0]])
			pose[&"brazo_tras"] = _claves(k, [[0.0, 0.0], [0.38, -3.05], [0.52, -0.75], [0.8, -0.7], [1.0, 0.0]])
			pose[&"antebrazo_del"] = _claves(k, [[0.0, 0.0], [0.38, 0.5], [0.52, -0.1], [1.0, 0.0]])
			pose[&"antebrazo_tras"] = _claves(k, [[0.0, 0.0], [0.38, -0.5], [0.52, 0.1], [1.0, 0.0]])
			pose[&"torso_rot"] += _claves(k, [[0.0, 0.0], [0.38, -0.12], [0.52, 0.24], [0.8, 0.2], [1.0, 0.0]])
			pose[&"lift"] = _claves(k, [[0.0, 0.0], [0.38, -5.0 * _u], [0.52, 1.5 * _u], [0.8, 1.0 * _u], [1.0, 0.0]])
			pose[&"estirar"] = _claves(k, [[0.0, 1.0], [0.38, 1.08], [0.52, 0.82], [0.66, 0.92], [1.0, 1.0]])
			pose[&"muslo_del"] = _claves(k, [[0.0, 0.0], [0.52, 0.32], [0.8, 0.32], [1.0, 0.0]])
			pose[&"muslo_tras"] = _claves(k, [[0.0, 0.0], [0.52, -0.32], [0.8, -0.32], [1.0, 0.0]])
			pose[&"pierna_del"] = _claves(k, [[0.0, 0.0], [0.52, -0.2], [0.8, -0.2], [1.0, 0.0]])
			pose[&"pierna_tras"] = _claves(k, [[0.0, 0.0], [0.52, 0.25], [0.8, 0.25], [1.0, 0.0]])
		&"zancada":
			# Embestida con el hombro: inclinado, el antebrazo grande delante como
			# un ariete y una zancada larga. Deja estela ámbar.
			var curva := _claves(k, [[0.0, 0.0], [0.12, 1.0], [0.6, 1.0], [1.0, 0.0]])
			pose[&"cuerpo_rot"] = 0.16 * curva
			pose[&"torso_rot"] += 0.3 * curva
			pose[&"brazo_del"] = -1.0 * curva
			pose[&"antebrazo_del"] = -1.5 * curva
			pose[&"brazo_tras"] = 0.85 * curva
			pose[&"antebrazo_tras"] = -0.3 * curva
			pose[&"muslo_del"] = 0.55 * curva
			pose[&"pierna_del"] = 0.45 * curva
			pose[&"muslo_tras"] = -0.6 * curva
			pose[&"pierna_tras"] = 0.15 * curva
			pose[&"torso_y"] += 2.5 * _u * curva
			_estela(delta, Color(1.0, 0.6, 0.2, 0.55), 0.04, k < 0.6)
		&"paso":
			# Salto corto y ágil: se agacha, salta encogido y aterriza.
			pose[&"lift"] = _claves(k, [[0.0, 0.0], [0.15, 1.5 * _u], [0.5, -7.0 * _u], [0.85, 0.0], [1.0, 0.0]])
			pose[&"estirar"] = _claves(k, [[0.0, 1.0], [0.15, 0.86], [0.35, 1.08], [0.85, 0.86], [1.0, 1.0]])
			var encogido := _claves(k, [[0.0, 0.0], [0.2, 1.0], [0.75, 1.0], [1.0, 0.0]])
			pose[&"muslo_del"] = -0.35 * encogido
			pose[&"muslo_tras"] = -0.55 * encogido
			pose[&"pierna_del"] = 0.8 * encogido
			pose[&"pierna_tras"] = 0.9 * encogido
			pose[&"brazo_del"] = 0.7 * encogido
			pose[&"brazo_tras"] = -0.7 * encogido
			pose[&"antebrazo_del"] = -0.4 * encogido
			pose[&"antebrazo_tras"] = 0.4 * encogido
			pose[&"cuerpo_rot"] = 0.12 * encogido
			_estela(delta, Color(0.6, 0.75, 0.9, 0.45), 0.06, k < 0.8)


func _pose_muerte(pose: Dictionary, delta: float) -> void:
	_muerte_t += delta
	var k := smoothstep(0.0, 1.0, minf(_muerte_t / 0.8, 1.0))
	pose[&"cuerpo_rot"] = -PI * 0.5 * k
	pose[&"brazo_del"] = 1.2 * k
	pose[&"brazo_tras"] = -1.0 * k
	pose[&"muslo_tras"] = -0.4 * k
	pose[&"lift"] = -1.0 * _u * k
	tinte = Color(0.75, 0.7, 0.7).lerp(Color(0.5, 0.45, 0.45, 0.9), k)


## Interpolación suave entre claves [[k, valor], ...].
func _claves(k: float, claves: Array) -> float:
	for i in range(1, claves.size()):
		var b: Array = claves[i]
		if k <= float(b[0]):
			var a: Array = claves[i - 1]
			var f := inverse_lerp(float(a[0]), float(b[0]), k)
			return lerpf(float(a[1]), float(b[1]), smoothstep(0.0, 1.0, f))
	return float((claves[-1] as Array)[1])


# --- Aplicar ---

func _aplicar_pose(pose: Dictionary) -> void:
	var estirar: float = pose[&"estirar"]
	_cuerpo.position = Vector2(pose[&"cuerpo_x"], pose[&"lift"])
	_cuerpo.rotation = pose[&"cuerpo_rot"]
	_cuerpo.scale = Vector2(1.0 / sqrt(estirar), estirar)
	if modo_entero:
		_entero.position.y = pose[&"torso_y"]
		_entero.rotation = pose[&"torso_rot"] * 0.6 + float(pose.get(&"muslo_del", 0.0)) * 0.15
		return
	# El torso primero y luego cada pieza tras su padre.
	var globales := {}
	var pendientes: Array = _orden.duplicate()
	while not pendientes.is_empty():
		for nombre: String in pendientes.duplicate():
			var pieza: Dictionary = _rig["piezas"][nombre]
			var padre: String = pieza["padre"]
			if padre != "" and not globales.has(padre):
				continue
			var local: Transform2D
			if padre == "":
				local = Transform2D(pose[&"torso_rot"], _v(pieza["enganche"]) + Vector2(0.0, pose[&"torso_y"]))
			else:
				local = (globales[padre] as Transform2D) * Transform2D(float(pose.get(StringName(nombre), 0.0)),
					_v(pieza["enganche"]))
			globales[nombre] = local
			(_sprites[nombre] as Sprite2D).transform = local
			pendientes.erase(nombre)


## Punto de una pieza (u, v en su textura) en coordenadas globales.
func _punto_de(nombre: String, uv: Vector2) -> Vector2:
	var sprite: Sprite2D = _sprites.get(nombre)
	if sprite == null or modo_entero:
		return global_position
	var local := sprite.offset + uv * sprite.texture.get_size()
	return sprite.global_transform * local


func _punto_impacto() -> Vector2:
	match _accion:
		&"punetazo":
			return _punto_de("antebrazo_tras", Vector2(0.5, 0.9))
		&"martillo":
			return _punto_de("antebrazo_del", Vector2(0.5, 0.9))
		_:
			return global_position


## Estela de copias que se desvanecen (zancada, paso).
func _estela(delta: float, color: Color, intervalo: float, activa: bool) -> void:
	_fantasma_t -= delta
	if not activa or _fantasma_t > 0.0 or capa_fantasmas == null or modo_entero:
		return
	_fantasma_t = intervalo
	var fantasma := Node2D.new()
	capa_fantasmas.add_child(fantasma)
	fantasma.global_transform = _piezas.global_transform
	for nombre: String in _orden:
		var original: Sprite2D = _sprites[nombre]
		var copia := Sprite2D.new()
		copia.texture = original.texture
		copia.centered = false
		copia.offset = original.offset
		copia.transform = original.transform
		fantasma.add_child(copia)
	fantasma.modulate = color
	var tween := fantasma.create_tween()
	tween.tween_property(fantasma, "modulate:a", 0.0, 0.25)
	tween.tween_callback(fantasma.queue_free)


func _v(arr: Array) -> Vector2:
	return Vector2(float(arr[0]), float(arr[1]))
