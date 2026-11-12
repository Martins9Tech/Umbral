class_name AbilitySlot
extends Control
## Habilidad del HUD (estilo MOBA): medallón con icono, barrido circular de
## enfriamiento, tecla en una insignia y nombre debajo. Late cuando está lista.
## Si `icon` es null se dibuja un glifo (`glyph`) hasta tener iconos pintados.

const BACKGROUND := Color(0.06, 0.045, 0.04, 0.92)
const IDLE_BORDER := Color(0.36, 0.3, 0.26)

var key_text := ""
var title := ""
var accent := Color(0.45, 0.8, 1.0)
var glyph: StringName = &""
var icon: Texture2D
var fill := 0.0
var is_ready := false
var is_active := false
var center_text := ""
var _pulse := 0.0
var _was_ready := false
var _ready_flash := 0.0


func _init(p_key: String, p_title: String, p_accent: Color, slot_size: float, p_glyph: StringName = &"") -> void:
	key_text = p_key
	title = p_title
	accent = p_accent
	glyph = p_glyph
	custom_minimum_size = Vector2(slot_size, slot_size + 26.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_state(p_fill: float, p_ready: bool, p_center: String, p_active: bool = false) -> void:
	fill = clampf(p_fill, 0.0, 1.0)
	if p_ready and not _was_ready:
		_ready_flash = 1.0
	_was_ready = p_ready
	is_ready = p_ready
	is_active = p_active
	center_text = p_center
	queue_redraw()


func _process(delta: float) -> void:
	_ready_flash = maxf(0.0, _ready_flash - delta * 2.5)
	if is_ready or is_active or _ready_flash > 0.0:
		_pulse += delta
		queue_redraw()


func _draw() -> void:
	var side := size.x
	var c := Vector2(side * 0.5, side * 0.5)
	var r := side * 0.46
	var lit := is_ready or is_active
	var wave := 0.5 + 0.5 * sin(_pulse * 6.0)
	# Halo cuando está lista y destello al cargarse.
	if lit:
		draw_circle(c, r + 6.0 + 3.0 * wave, Color(accent, 0.18 + 0.1 * wave))
	if _ready_flash > 0.0:
		draw_circle(c, r + 14.0 * (1.0 - _ready_flash), Color(accent, 0.5 * _ready_flash))
	draw_circle(c, r, BACKGROUND)
	# Icono (o glifo) y, encima, la parte que falta por cargar en oscuro.
	_draw_icon(c, r * 0.62, Color.WHITE if lit else Color(0.75, 0.72, 0.7))
	if fill < 1.0 and not is_active:
		var points := PackedVector2Array([c])
		var start := -PI / 2.0 + TAU * fill
		var steps := 40
		for k in steps + 1:
			points.append(c + Vector2.from_angle(start + (TAU * (1.0 - fill)) * k / steps) * r)
		if points.size() >= 3:
			draw_colored_polygon(points, Color(0.0, 0.0, 0.0, 0.62))
		# Borde de progreso.
		draw_arc(c, r - 2.0, -PI / 2.0, -PI / 2.0 + TAU * fill, 48, Color(accent, 0.85), 4.0)
	var border := accent.lerp(Color.WHITE, 0.35 * wave) if lit else IDLE_BORDER
	draw_arc(c, r, 0.0, TAU, 64, border, 3.0 + (2.0 * wave if lit else 0.0))
	draw_arc(c, r + 3.5, 0.0, TAU, 64, Color(0, 0, 0, 0.6), 1.5)

	var font := get_theme_default_font()
	if not center_text.is_empty():
		var big := 30 if center_text.length() <= 4 else 20
		draw_string_outline(font, Vector2(0.0, c.y + big * 0.35), center_text, HORIZONTAL_ALIGNMENT_CENTER, side, big, 6,
			Color(0, 0, 0, 0.9))
		draw_string(font, Vector2(0.0, c.y + big * 0.35), center_text, HORIZONTAL_ALIGNMENT_CENTER, side, big,
			Color.WHITE if lit else Color(0.92, 0.9, 0.88))
	# Tecla en una insignia arriba a la izquierda.
	if not key_text.is_empty():
		var badge_w := maxf(26.0, font.get_string_size(key_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x + 12.0)
		var badge := Rect2(Vector2(0.0, 0.0), Vector2(badge_w, 24.0))
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.1, 0.08, 0.07, 0.95)
		style.border_color = Color(accent, 0.9)
		style.set_border_width_all(2)
		style.set_corner_radius_all(6)
		draw_style_box(style, badge)
		draw_string(font, Vector2(0.0, 17.0), key_text, HORIZONTAL_ALIGNMENT_CENTER, badge_w, 14, Color.WHITE)
	# Nombre debajo.
	draw_string_outline(font, Vector2(-22.0, side + 18.0), title, HORIZONTAL_ALIGNMENT_CENTER, side + 44.0, 13, 5,
		Color(0, 0, 0, 0.85))
	draw_string(font, Vector2(-22.0, side + 18.0), title, HORIZONTAL_ALIGNMENT_CENTER, side + 44.0, 13,
		accent.lightened(0.4) if lit else Color(0.85, 0.82, 0.78))


func _draw_icon(c: Vector2, s: float, tint: Color) -> void:
	if icon != null:
		UiStyle.draw_icon_circle(self, icon, c, s / 0.62 - 3.0, tint)
		return
	var col := Color(accent.lerp(Color.WHITE, 0.25), tint.a) * Color(tint.r, tint.g, tint.b)
	var dark := Color(0.06, 0.045, 0.04)
	match glyph:
		&"rasgo":
			# Capas de piedra apiladas.
			for k in 3:
				var y := c.y + s * (0.55 - 0.5 * k)
				var w := s * (1.3 - 0.25 * k)
				var stone := PackedVector2Array([Vector2(c.x - w, y), Vector2(c.x - w * 0.8, y - s * 0.38),
					Vector2(c.x + w * 0.8, y - s * 0.4), Vector2(c.x + w, y)])
				draw_colored_polygon(stone, col.darkened(0.15 * k))
				draw_polyline(stone, dark, 2.0)
		&"tecnica":
			# Embestida: flecha con grieta.
			draw_colored_polygon(PackedVector2Array([c + Vector2(-s, -s * 0.3), c + Vector2(s * 0.2, -s * 0.3),
				c + Vector2(s * 0.2, -s * 0.75), c + Vector2(s * 1.1, 0.0), c + Vector2(s * 0.2, s * 0.75),
				c + Vector2(s * 0.2, s * 0.3), c + Vector2(-s, s * 0.3)]), col)
			draw_polyline(PackedVector2Array([c + Vector2(-s, s * 0.9), c + Vector2(-s * 0.4, s * 0.6),
				c + Vector2(0.0, s * 1.0), c + Vector2(s * 0.5, s * 0.7)]), col, 3.0)
		&"definitiva":
			# Monte que despierta: montaña con runa.
			draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 1.2, s * 0.8), c + Vector2(-s * 0.3, -s * 0.9),
				c + Vector2(s * 0.2, -s * 0.2), c + Vector2(s * 0.55, -s * 0.6), c + Vector2(s * 1.2, s * 0.8)]), col)
			draw_circle(c + Vector2(-s * 0.05, s * 0.25), s * 0.22, dark)
			draw_arc(c + Vector2(-s * 0.05, s * 0.25), s * 0.22, 0.0, TAU, 16, Color(1.0, 0.75, 0.3), 2.0)
		&"paso":
			# Esquiva: tres cuñas.
			for k in 3:
				var x := c.x - s * 0.9 + s * 0.65 * k
				draw_colored_polygon(PackedVector2Array([Vector2(x, c.y - s * 0.8), Vector2(x + s * 0.55, c.y),
					Vector2(x, c.y + s * 0.8), Vector2(x + s * 0.25, c.y)]), Color(col, 0.45 + 0.27 * k))
