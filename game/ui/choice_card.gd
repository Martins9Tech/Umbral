class_name ChoiceCard
extends Button
## Carta de elección (subida de nivel, aumentos, tienda). Cada categoría tiene
## su color y su icono, para distinguir de un vistazo arma, reliquia, kit,
## aumento, evolución o curación. Entra con una pequeña animación y crece al
## pasar el ratón o el mando por encima.

const SIZE := Vector2(330.0, 430.0)
const BG := Color(0.075, 0.06, 0.055, 0.97)
const BG_HOVER := Color(0.12, 0.095, 0.085, 0.99)
const TEXT := Color(0.86, 0.82, 0.78)
const CATEGORIES := {
	&"arma": {"name": "ARMA", "color": Color("e8643a"), "icon": &"espada"},
	&"reliquia": {"name": "RELIQUIA", "color": Color("3fb8c9"), "icon": &"gema"},
	&"kit": {"name": "KIT DEL CAMPEÓN", "color": Color("ffae3d"), "icon": &"runa"},
	&"aumento": {"name": "AUMENTO", "color": Color("a24dff"), "icon": &"estrella"},
	&"evolucion": {"name": "EVOLUCIÓN", "color": Color("ffd34d"), "icon": &"llama"},
	&"curacion": {"name": "CURACIÓN", "color": Color("3fd46a"), "icon": &"corazon"},
}

var category: StringName = &"arma"
var accent := Color.WHITE
var _hover := false


## Crea la carta. `level` es el texto pequeño bajo el título (p. ej. "NV 2 → 3");
## `ribbon` una cinta en la esquina (p. ej. "SINERGIA"); `emblem_color` tiñe
## el icono central (p. ej. el elemento del arma).
static func create(p_category: StringName, index: int, title: String, level: String, description: String,
		p_accent: Color = Color.TRANSPARENT, ribbon: String = "", emblem_color: Color = Color.TRANSPARENT,
		category_name: String = "", card_size: Vector2 = SIZE, icon: Texture2D = null) -> ChoiceCard:
	var card := ChoiceCard.new()
	card.category = p_category
	var info: Dictionary = CATEGORIES.get(p_category, CATEGORIES[&"arma"])
	card.accent = p_accent if p_accent.a > 0.0 else info["color"]
	card.custom_minimum_size = card_size
	card.focus_mode = Control.FOCUS_ALL
	card.pivot_offset = card_size * 0.5
	for state: String in ["normal", "hover", "focus", "pressed", "disabled"]:
		card.add_theme_stylebox_override(state, StyleBoxEmpty.new())

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 24.0
	box.offset_right = -24.0
	box.offset_top = 58.0
	box.offset_bottom = -22.0
	box.add_theme_constant_override("separation", 8)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(box)
	var emblem := CardEmblem.new()
	emblem.icon = info["icon"]
	emblem.color = card.accent
	emblem.inner = emblem_color if emblem_color.a > 0.0 else card.accent
	emblem.texture = icon
	emblem.custom_minimum_size = Vector2(0.0, card_size.y * 0.27)
	box.add_child(emblem)
	var title_label := _label(title, 22 if card_size.y >= SIZE.y else 20, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	title_label.add_theme_font_override("font", UiTheme.title_font())
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(title_label)
	if not level.is_empty():
		box.add_child(_label(level, 17, card.accent, HORIZONTAL_ALIGNMENT_CENTER))
	var separator := ColorRect.new()
	separator.color = Color(card.accent, 0.35)
	separator.custom_minimum_size = Vector2(0.0, 2.0)
	separator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(separator)
	var text := _label(description, 17 if card_size.y >= SIZE.y else 15, TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(text)

	card.set_meta(&"header", category_name if not category_name.is_empty() else str(info["name"]))
	card.set_meta(&"key", str(index + 1))
	card.set_meta(&"ribbon", ribbon)
	card.mouse_entered.connect(card._set_hover.bind(true))
	card.mouse_exited.connect(card._set_hover.bind(false))
	card.focus_entered.connect(card._set_hover.bind(true))
	card.focus_exited.connect(card._set_hover.bind(false))
	return card


## Carta para una opción de subida de nivel o cofre (ver UpgradeOffer).
static func from_upgrade(option: Dictionary, index: int, card_size: Vector2 = SIZE, ribbon_override: String = "") -> ChoiceCard:
	var kind: StringName = option.get("kind", &"heal")
	var parts := str(option.get("title", "")).split("  ·  ")
	var title := parts[0]
	var level := " · ".join(parts.slice(1)).to_upper()
	var category := &"arma"
	var header := ""
	var emblem := Color.TRANSPARENT
	var ribbon := ""
	var icon: Texture2D = null
	match kind:
		&"weapon_up":
			var weapon: Weapon = option["weapon"]
			level = "NV %d  →  %d" % [weapon.level, weapon.level + 1]
			emblem = UiStyle.tag_color(weapon.data.tags)
			icon = UiStyle.icon(weapon.data.id)
		&"weapon_new":
			var data: WeaponData = option["data"]
			emblem = UiStyle.tag_color(data.tags)
			header = "ARMA NUEVA"
			icon = UiStyle.icon(data.id)
		&"relic":
			category = &"reliquia"
			icon = UiStyle.icon((option["data"] as RelicData).id)
		&"technique":
			category = &"kit"
			header = "TÉCNICA"
			icon = UiStyle.icon(&"zancada_de_falla")
		&"ultimate":
			category = &"kit"
			header = "DEFINITIVA"
			icon = UiStyle.icon(&"despertar_del_monte")
		&"heal":
			category = &"curacion"
	if option.get("evolution", false):
		if category == &"arma":
			category = &"evolucion"
			header = "ARMA · EVOLUCIÓN"
		ribbon = "CLAVE PARA EVOLUCIONAR"
	elif option.get("synergy", false):
		ribbon = "SINERGIA"
	if not ribbon_override.is_empty():
		ribbon = ribbon_override
	return create(category, index, title, level, str(option.get("description", "")), Color.TRANSPARENT,
		ribbon, emblem, header, card_size, icon)


## Entrada escalonada: aparece desde abajo y crece hasta su tamaño.
func appear(delay: float) -> void:
	modulate.a = 0.0
	scale = Vector2.ONE * 0.85
	var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 0.18).set_delay(delay)
	tween.tween_property(self, "scale", Vector2.ONE, 0.28).set_delay(delay)


func _set_hover(value: bool) -> void:
	if _hover == value or disabled:
		return
	_hover = value
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE * (1.05 if value else 1.0), 0.12)
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	var lit := _hover and not disabled
	# Sombra y resplandor del color de la categoría.
	var glow := StyleBoxFlat.new()
	glow.bg_color = Color(0, 0, 0, 0)
	glow.shadow_color = Color(accent, 0.45) if lit else Color(0, 0, 0, 0.55)
	glow.shadow_size = 22 if lit else 14
	glow.set_corner_radius_all(14)
	draw_style_box(glow, rect)
	var panel := StyleBoxFlat.new()
	panel.bg_color = BG_HOVER if lit else BG
	panel.border_color = accent.lightened(0.25) if lit else Color(accent, 0.8)
	panel.set_border_width_all(3 if lit else 2)
	panel.set_corner_radius_all(14)
	draw_style_box(panel, rect)
	# Cabecera con el color de la categoría.
	var header := StyleBoxFlat.new()
	header.bg_color = Color(accent.darkened(0.45), 0.95)
	header.corner_radius_top_left = 12
	header.corner_radius_top_right = 12
	draw_style_box(header, Rect2(3, 3, size.x - 6, 44))
	draw_rect(Rect2(3, 46, size.x - 6, 2), Color(accent, 0.9))
	var font := get_theme_default_font()
	draw_string(font, Vector2(20, 33), str(get_meta(&"header", "")), HORIZONTAL_ALIGNMENT_LEFT, size.x - 80, 17,
		accent.lightened(0.55))
	# Tecla de atajo en un círculo.
	var key_center := Vector2(size.x - 28, 25)
	draw_circle(key_center, 15, Color(0, 0, 0, 0.45))
	draw_arc(key_center, 15, 0, TAU, 24, Color(accent, 0.9), 2.0)
	draw_string(font, key_center + Vector2(-15, 7), str(get_meta(&"key", "")), HORIZONTAL_ALIGNMENT_CENTER, 30, 18,
		Color.WHITE)
	# Cinta en la esquina (sinergia, evolución...).
	var ribbon: String = get_meta(&"ribbon", "")
	if not ribbon.is_empty():
		var ribbon_rect := Rect2(size.x * 0.5 - 85, size.y - 16, 170, 30)
		var tag := StyleBoxFlat.new()
		tag.bg_color = accent
		tag.set_corner_radius_all(15)
		draw_style_box(tag, ribbon_rect)
		draw_string(font, ribbon_rect.position + Vector2(0, 21), ribbon, HORIZONTAL_ALIGNMENT_CENTER, ribbon_rect.size.x,
			15, Color(0.08, 0.06, 0.05))
	if disabled:
		draw_rect(rect, Color(0, 0, 0, 0.55))


static func _label(text: String, font_size: int, color: Color, align: HorizontalAlignment) -> Label:
	var label := UiStyle.label(font_size, align)
	label.text = text
	label.add_theme_color_override("font_color", color)
	return label


## Icono central de la carta, dibujado con formas (hasta tener iconos pintados).
class CardEmblem:
	extends Control

	var icon: StringName = &"espada"
	var color := Color.WHITE
	var inner := Color.WHITE
	var texture: Texture2D

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c := Vector2(size.x * 0.5, size.y * 0.5)
		var r := minf(size.y * 0.46, 54.0)
		# Medallón: halo, disco oscuro y doble aro.
		draw_circle(c, r + 10, Color(color, 0.12))
		draw_circle(c, r, Color(0.05, 0.04, 0.035))
		draw_arc(c, r, 0, TAU, 48, Color(color, 0.9), 3.0)
		draw_arc(c, r - 7, 0, TAU, 48, Color(color, 0.3), 1.5)
		if texture != null:
			UiStyle.draw_icon_circle(self, texture, c, r - 4.0)
			draw_arc(c, r, 0, TAU, 48, Color(color, 0.95), 3.0)
			return
		var s := r * 0.55
		var fill := inner
		var dark := Color(0.05, 0.04, 0.035)
		match icon:
			&"espada":
				var blade := PackedVector2Array([c + Vector2(0, -s * 1.15), c + Vector2(s * 0.18, -s * 0.85),
					c + Vector2(s * 0.18, s * 0.35), c + Vector2(-s * 0.18, s * 0.35), c + Vector2(-s * 0.18, -s * 0.85)])
				draw_colored_polygon(blade, fill)
				draw_line(c + Vector2(0, -s), c + Vector2(0, s * 0.3), Color(dark, 0.4), 2.0)
				draw_rect(Rect2(c + Vector2(-s * 0.6, s * 0.35), Vector2(s * 1.2, s * 0.2)), fill.darkened(0.2))
				draw_rect(Rect2(c + Vector2(-s * 0.12, s * 0.55), Vector2(s * 0.24, s * 0.45)), fill.darkened(0.45))
				draw_circle(c + Vector2(0, s * 1.08), s * 0.15, fill.darkened(0.2))
			&"gema":
				var top := c + Vector2(0, -s)
				var gem := PackedVector2Array([c + Vector2(-s * 0.9, -s * 0.25), c + Vector2(-s * 0.45, -s * 0.8),
					c + Vector2(s * 0.45, -s * 0.8), c + Vector2(s * 0.9, -s * 0.25), c + Vector2(0, s * 1.0)])
				draw_colored_polygon(gem, fill)
				draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.9, -s * 0.25), c + Vector2(s * 0.9, -s * 0.25),
					c + Vector2(0, s * 1.0)]), fill.darkened(0.25))
				draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.45, -s * 0.8), c + Vector2(0, -s * 0.25),
					c + Vector2(-s * 0.9, -s * 0.25)]), fill.lightened(0.35))
				draw_line(top + Vector2(0, s * 0.2), c + Vector2(0, -s * 0.25), Color(1, 1, 1, 0.5), 2.0)
			&"runa":
				var hexagon := PackedVector2Array()
				for k in 7:
					hexagon.append(c + Vector2.from_angle(TAU * k / 6.0 - PI / 2.0) * s)
				draw_polyline(hexagon, fill, 5.0)
				draw_circle(c, s * 0.28, fill)
				draw_line(c + Vector2(0, s * 0.3), c + Vector2(0, s * 1.0), fill, 4.0)
			&"estrella":
				var star := PackedVector2Array()
				for k in 8:
					var radius := s * (1.15 if k % 2 == 0 else 0.4)
					star.append(c + Vector2.from_angle(TAU * k / 8.0 - PI / 2.0) * radius)
				draw_colored_polygon(star, fill)
				draw_circle(c, s * 0.22, Color(1, 1, 1, 0.8))
			&"llama":
				var flame := PackedVector2Array([c + Vector2(0, -s * 1.15), c + Vector2(s * 0.55, -s * 0.2),
					c + Vector2(s * 0.7, s * 0.45), c + Vector2(s * 0.35, s * 0.95), c + Vector2(-s * 0.35, s * 0.95),
					c + Vector2(-s * 0.7, s * 0.45), c + Vector2(-s * 0.3, -s * 0.1)])
				draw_colored_polygon(flame, fill)
				draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s * 0.3), c + Vector2(s * 0.35, s * 0.4),
					c + Vector2(0, s * 0.9), c + Vector2(-s * 0.35, s * 0.4)]), Color(1, 1, 1, 0.75))
			&"corazon":
				draw_circle(c + Vector2(-s * 0.42, -s * 0.25), s * 0.5, fill)
				draw_circle(c + Vector2(s * 0.42, -s * 0.25), s * 0.5, fill)
				draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.9, -s * 0.05), c + Vector2(s * 0.9, -s * 0.05),
					c + Vector2(0, s * 0.95)]), fill)
				draw_circle(c + Vector2(-s * 0.5, -s * 0.4), s * 0.14, Color(1, 1, 1, 0.6))
