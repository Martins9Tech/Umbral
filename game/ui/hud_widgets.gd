class_name HudWidgets
## Piezas del HUD dibujadas por código: marco del campeón (retrato, nivel y
## vida con estela de daño), barra de experiencia y contadores con icono.

const PANEL := Color(0.06, 0.045, 0.04, 0.88)
const EDGE := Color(0.42, 0.33, 0.24)
const GOLD := Color("ffc94d")
const HP := Color("d9443a")
const HP_DARK := Color("6e1a16")
const XP := Color("3fd46a")


## Retrato circular con nivel y barra de vida (la vida perdida se ve como una
## estela clara que baja con retraso).
class PlayerFrame:
	extends Control

	var portrait: Texture2D
	var level := 1
	var hp := 1.0
	var max_hp := 1.0
	var _trail := 1.0
	var _hurt := 0.0

	func _init() -> void:
		custom_minimum_size = Vector2(430.0, 112.0)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func set_values(p_level: int, p_hp: float, p_max: float) -> void:
		if p_hp < hp - 0.5:
			_hurt = 1.0
		level = p_level
		hp = p_hp
		max_hp = maxf(p_max, 1.0)
		queue_redraw()

	func _process(delta: float) -> void:
		var ratio := hp / max_hp
		if _trail > ratio:
			_trail = maxf(ratio, _trail - delta * 0.35)
		else:
			_trail = ratio
		_hurt = maxf(0.0, _hurt - delta * 3.0)
		queue_redraw()

	func _draw() -> void:
		var c := Vector2(56.0, 56.0)
		var r := 50.0
		var font := get_theme_default_font()
		# Barra de vida, detrás del retrato.
		var bar := Rect2(80.0, 36.0, 340.0, 34.0)
		var back := StyleBoxFlat.new()
		back.bg_color = PANEL
		back.border_color = EDGE
		back.set_border_width_all(2)
		back.set_corner_radius_all(8)
		draw_style_box(back, bar)
		var inner := bar.grow(-4.0)
		var ratio := clampf(hp / max_hp, 0.0, 1.0)
		_fill(Rect2(inner.position, Vector2(inner.size.x * _trail, inner.size.y)), Color(1.0, 0.85, 0.7, 0.8))
		_fill(Rect2(inner.position, Vector2(inner.size.x * ratio, inner.size.y)), HP.lerp(Color.WHITE, 0.5 * _hurt))
		draw_rect(Rect2(inner.position, Vector2(inner.size.x * ratio, inner.size.y * 0.4)), Color(1, 1, 1, 0.12))
		var text := "%d / %d" % [ceili(hp), roundi(max_hp)]
		draw_string_outline(font, Vector2(inner.position.x, inner.position.y + 20.0), text, HORIZONTAL_ALIGNMENT_CENTER,
			inner.size.x, 17, 5, Color(0, 0, 0, 0.9))
		draw_string(font, Vector2(inner.position.x, inner.position.y + 20.0), text, HORIZONTAL_ALIGNMENT_CENTER,
			inner.size.x, 17, Color.WHITE)
		# Retrato en un medallón.
		draw_circle(c, r + 4.0, Color(0, 0, 0, 0.6))
		draw_circle(c, r, PANEL)
		if portrait != null:
			var points := PackedVector2Array()
			var uvs := PackedVector2Array()
			# Recorte de la cabeza y los hombros del retrato.
			var uv_center := Vector2(0.5, 0.27)
			var uv_radius := 0.21
			for k in 40:
				var dir := Vector2.from_angle(TAU * k / 40.0)
				points.append(c + dir * (r - 3.0))
				uvs.append(uv_center + dir * uv_radius)
			draw_polygon(points, PackedColorArray([Color.WHITE]), uvs, portrait)
		draw_arc(c, r, 0.0, TAU, 64, GOLD.darkened(0.25), 3.0)
		draw_arc(c, r - 4.0, 0.0, TAU, 64, Color(0, 0, 0, 0.5), 2.0)
		# Nivel en una insignia.
		var badge := c + Vector2(34.0, 36.0)
		draw_circle(badge, 19.0, Color(0.1, 0.07, 0.05))
		draw_arc(badge, 19.0, 0.0, TAU, 32, GOLD, 2.5)
		draw_string(font, badge + Vector2(-19.0, 7.0), str(level), HORIZONTAL_ALIGNMENT_CENTER, 38.0, 20, GOLD)

	func _fill(rect: Rect2, color: Color) -> void:
		if rect.size.x <= 1.0:
			return
		var style := StyleBoxFlat.new()
		style.bg_color = color
		style.set_corner_radius_all(5)
		draw_style_box(style, rect)


## Barra de experiencia a lo ancho de la pantalla, con brillo al avanzar.
class XpBar:
	extends Control

	var value := 0.0
	var max_value := 1.0
	var _shown := 0.0
	var _glow := 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func set_values(p_value: float, p_max: float) -> void:
		var ratio := clampf(p_value / maxf(p_max, 0.001), 0.0, 1.0)
		if ratio > _shown + 0.001:
			_glow = 1.0
		value = p_value
		max_value = p_max

	func _process(delta: float) -> void:
		var ratio := clampf(value / maxf(max_value, 0.001), 0.0, 1.0)
		_shown = ratio if ratio < _shown else lerpf(_shown, ratio, 1.0 - exp(-12.0 * delta))
		_glow = maxf(0.0, _glow - delta * 2.0)
		queue_redraw()

	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		draw_rect(rect, Color(0.03, 0.025, 0.02, 0.9))
		var fill := Rect2(rect.position, Vector2(rect.size.x * _shown, rect.size.y))
		draw_rect(fill, XP.darkened(0.25))
		draw_rect(Rect2(fill.position, Vector2(fill.size.x, fill.size.y * 0.45)), XP.lightened(0.15))
		if fill.size.x > 2.0:
			draw_rect(Rect2(fill.end.x - 3.0, 0.0, 3.0, size.y), Color(1, 1, 1, 0.5 + 0.5 * _glow))
		draw_rect(Rect2(0.0, size.y - 2.0, size.x, 2.0), Color(0, 0, 0, 0.8))


## Contador con icono dibujado (calavera = muertes, moneda = oro).
class StatCounter:
	extends Control

	var kind: StringName = &"muertes"
	var value := 0
	var color := Color.WHITE
	var _bump := 0.0

	func _init(p_kind: StringName, p_color: Color) -> void:
		kind = p_kind
		color = p_color
		custom_minimum_size = Vector2(170.0, 40.0)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func set_value(p_value: int) -> void:
		if p_value != value:
			_bump = 1.0
		value = p_value

	func _process(delta: float) -> void:
		_bump = maxf(0.0, _bump - delta * 6.0)
		queue_redraw()

	func _draw() -> void:
		var font := get_theme_default_font()
		var c := Vector2(size.x - 20.0, size.y * 0.5)
		match kind:
			&"oro":
				draw_circle(c, 13.0, color.darkened(0.35))
				draw_circle(c, 10.5, color)
				draw_circle(c + Vector2(-3.0, -3.0), 3.5, Color(1, 1, 1, 0.55))
			_:
				draw_circle(c + Vector2(0, -2), 12.0, Color(0.92, 0.88, 0.8))
				draw_rect(Rect2(c + Vector2(-7, 6), Vector2(14, 7)), Color(0.92, 0.88, 0.8))
				draw_circle(c + Vector2(-4.5, -2), 3.5, Color(0.1, 0.07, 0.06))
				draw_circle(c + Vector2(4.5, -2), 3.5, Color(0.1, 0.07, 0.06))
		var text := str(value)
		var font_size := int(24.0 + 6.0 * _bump)
		var width := size.x - 44.0
		draw_string_outline(font, Vector2(0.0, size.y * 0.5 + 9.0), text, HORIZONTAL_ALIGNMENT_RIGHT, width, font_size, 6,
			Color(0, 0, 0, 0.9))
		draw_string(font, Vector2(0.0, size.y * 0.5 + 9.0), text, HORIZONTAL_ALIGNMENT_RIGHT, width, font_size,
			color if kind == &"oro" else Color.WHITE)
