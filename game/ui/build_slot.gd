class_name BuildSlot
extends Control
## Casilla del HUD para un arma o una reliquia: siglas, nivel en grande y una
## fila de marcas con el progreso hasta el máximo. Borde dorado si está
## evolucionada; borde dorado que late si está lista para evolucionar.

const BACKGROUND := Color(0.05, 0.05, 0.08, 0.85)
const EMPTY_BORDER := Color(0.3, 0.3, 0.35, 0.6)
const GOLD := Color(1.0, 0.8, 0.3)

var _empty := true
var _initials := ""
var _level := 0
var _max_level := 1
var _tint := Color.GRAY
var _evolved := false
var _evolution_ready := false
var _signature := false
var _ghost := false
var _badge := ""
var _icon: Texture2D
var _pulse := 0.0


func _init(slot_size: float) -> void:
	custom_minimum_size = Vector2(slot_size, slot_size)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_item(display_name: String, level: int, max_level: int, tint: Color,
		evolved: bool = false, evolution_ready: bool = false, signature: bool = false) -> void:
	_empty = false
	_ghost = false
	_badge = ""
	_initials = initials_of(display_name)
	_icon = UiStyle.icon_for_name(display_name)
	_level = level
	_max_level = maxi(max_level, 1)
	_tint = tint
	_evolved = evolved
	_evolution_ready = evolution_ready
	_signature = signature
	queue_redraw()


## Insignia sin niveles (aumentos): siglas y una etiqueta corta (rareza).
func set_badge(display_name: String, tint: Color, badge: String) -> void:
	_empty = false
	_ghost = false
	_badge = badge
	_initials = initials_of(display_name)
	_icon = UiStyle.icon_for_name(display_name)
	_tint = tint
	_evolution_ready = false
	_evolved = false
	queue_redraw()


## Casilla "fantasma": algo que aún no tienes (p. ej. la reliquia de una receta).
func set_ghost(display_name: String, tint: Color) -> void:
	_empty = false
	_ghost = true
	_initials = initials_of(display_name)
	_icon = UiStyle.icon_for_name(display_name)
	_tint = tint
	_evolution_ready = false
	queue_redraw()


func set_empty() -> void:
	if not _empty:
		_empty = true
		queue_redraw()


func _process(delta: float) -> void:
	if _evolution_ready and not _empty:
		_pulse += delta
		queue_redraw()


func _box(rect: Rect2, color: Color, border: Color = Color.TRANSPARENT, width: int = 0) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(8)
	if width > 0:
		style.border_color = border
		style.set_border_width_all(width)
		style.draw_center = color.a > 0.0
	draw_style_box(style, rect)


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	_box(rect, BACKGROUND)
	if _empty:
		_box(rect.grow(-2.0), Color(0, 0, 0, 0), EMPTY_BORDER, 1)
		return
	var font_size := clampi(int(size.y * 0.36), 14, 26)
	if _icon != null:
		_draw_with_icon(rect)
		return
	if _ghost:
		draw_rect(Rect2(0.0, 0.0, size.x, size.y * 0.62), Color(_tint, 0.12))
		draw_string(ThemeDB.fallback_font, Vector2(0.0, size.y * 0.5), _initials, HORIZONTAL_ALIGNMENT_CENTER,
			size.x, font_size, Color(1, 1, 1, 0.3))
		draw_rect(rect.grow(-1.0), EMPTY_BORDER, false, 2.0)
		return

	if not _badge.is_empty():
		draw_rect(Rect2(0.0, 0.0, size.x, size.y), Color(_tint, 0.35))
		draw_string(ThemeDB.fallback_font, Vector2(0.0, size.y * 0.5), _initials, HORIZONTAL_ALIGNMENT_CENTER,
			size.x, font_size, Color.WHITE)
		draw_string(ThemeDB.fallback_font, Vector2(0.0, size.y * 0.86), _badge, HORIZONTAL_ALIGNMENT_CENTER,
			size.x, clampi(int(size.y * 0.2), 10, 15), _tint.lightened(0.3))
		draw_rect(rect, _tint, false, 2.5)
		return
	# Degradado del color de su elemento.
	_box(Rect2(2.0, 2.0, size.x - 4.0, size.y * 0.66), Color(_tint, 0.45))
	draw_rect(Rect2(4.0, 4.0, size.x - 8.0, size.y * 0.2), Color(1, 1, 1, 0.08))
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(0.0, size.y * 0.42), _initials, HORIZONTAL_ALIGNMENT_CENTER, size.x, font_size, Color.WHITE)
	var level_text := "EVO" if _evolved else ("MAX" if _level >= _max_level else str(_level))
	draw_string(font, Vector2(0.0, size.y * 0.82), level_text, HORIZONTAL_ALIGNMENT_CENTER, size.x,
		clampi(int(size.y * 0.25), 12, 18),
		GOLD if _evolved or _level >= _max_level else Color(0.95, 0.95, 1.0))

	# Marcas de nivel.
	var pip_gap := 2.0
	var pip_w := (size.x - 8.0 - pip_gap * (_max_level - 1)) / _max_level
	for k in _max_level:
		var pip := Rect2(4.0 + k * (pip_w + pip_gap), size.y - 9.0, pip_w, 5.0)
		var filled := _evolved or k < _level
		draw_rect(pip, GOLD if _evolved else (Color(0.95, 0.95, 1.0) if filled else Color(1, 1, 1, 0.15)))

	var border := Color(0.55, 0.55, 0.62)
	var width := 2.0
	if _evolved:
		border = GOLD
		width = 3.0
	elif _evolution_ready:
		var wave := 0.5 + 0.5 * sin(_pulse * 7.0)
		border = GOLD.lerp(Color.WHITE, 0.5 * wave)
		width = 3.0 + 3.0 * wave
	elif _signature:
		border = Color(0.85, 0.85, 0.95)
	_box(rect, Color(0, 0, 0, 0), border, int(width))


## Casilla con icono pintado: nivel en una esquina y marcas debajo.
func _draw_with_icon(rect: Rect2) -> void:
	var inner := rect.grow(-3.0)
	var tint := Color(1, 1, 1, 0.35) if _ghost else Color.WHITE
	draw_texture_rect(_icon, inner, false, tint)
	var font := ThemeDB.fallback_font
	if _badge.is_empty() and not _ghost:
		# Sombra abajo para leer el nivel y las marcas.
		draw_rect(Rect2(inner.position.x, inner.end.y - size.y * 0.3, inner.size.x, size.y * 0.3), Color(0, 0, 0, 0.55))
		var level_text := "EVO" if _evolved else ("MAX" if _level >= _max_level else str(_level))
		var font_size := clampi(int(size.y * 0.24), 11, 18)
		draw_string_outline(font, Vector2(0.0, size.y - 11.0), level_text, HORIZONTAL_ALIGNMENT_CENTER, size.x,
			font_size, 4, Color(0, 0, 0, 0.9))
		draw_string(font, Vector2(0.0, size.y - 11.0), level_text, HORIZONTAL_ALIGNMENT_CENTER, size.x, font_size,
			GOLD if _evolved or _level >= _max_level else Color.WHITE)
		var pip_gap := 1.5
		var pip_w := (size.x - 10.0 - pip_gap * (_max_level - 1)) / _max_level
		for k in _max_level:
			var filled := _evolved or k < _level
			draw_rect(Rect2(5.0 + k * (pip_w + pip_gap), size.y - 7.0, pip_w, 3.0),
				GOLD if _evolved else (Color(1, 1, 1, 0.95) if filled else Color(1, 1, 1, 0.18)))
	var border := Color(_tint, 0.9) if not _badge.is_empty() else Color(0.55, 0.47, 0.4)
	var width := 2
	if _evolved:
		border = GOLD
		width = 3
	elif _evolution_ready:
		var wave := 0.5 + 0.5 * sin(_pulse * 7.0)
		border = GOLD.lerp(Color.WHITE, 0.5 * wave)
		width = 3 + int(3.0 * wave)
	elif _signature:
		border = Color(0.9, 0.85, 0.75)
	elif _ghost:
		border = EMPTY_BORDER
	_box(rect, Color(0, 0, 0, 0), border, width)


static func initials_of(display_name: String) -> String:
	var words := display_name.split(" ", false)
	var letters := ""
	for word: String in words:
		if word.length() >= 3:  # salta "de", "del"...
			letters += word.substr(0, 1).to_upper()
		if letters.length() >= 2:
			break
	if letters.is_empty():
		letters = display_name.substr(0, 2).to_upper()
	return letters
