class_name UiStyle
## Ayudas para crear controles del prototipo con un estilo uniforme.

const ICON_DIR := "res://assets/ui/iconos/"

static var _icons := {}
static var _ids_by_name := {}


## Icono pintado de un arma, reliquia, aumento o habilidad (null si aún no hay).
static func icon(id: StringName) -> Texture2D:
	if id == &"":
		return null
	if not _icons.has(id):
		var path := ICON_DIR + "%s.png" % id
		_icons[id] = load(path) if ResourceLoader.exists(path) else null
	return _icons[id]


## Icono a partir del nombre visible (armas, reliquias y aumentos).
static func icon_for_name(display_name: String) -> Texture2D:
	if _ids_by_name.is_empty():
		for weapon: WeaponData in ContentDB.weapons:
			_ids_by_name[weapon.display_name] = weapon.id
		for relic: RelicData in ContentDB.relics:
			_ids_by_name[relic.display_name] = relic.id
		for augment: AugmentData in ContentDB.augments:
			_ids_by_name[augment.display_name] = augment.id
	return icon(_ids_by_name.get(display_name, &""))


## Dibuja un icono recortado en círculo.
static func draw_icon_circle(canvas: CanvasItem, texture: Texture2D, center: Vector2, radius: float,
		tint: Color = Color.WHITE) -> void:
	var points := PackedVector2Array()
	var uvs := PackedVector2Array()
	for k in 48:
		var dir := Vector2.from_angle(TAU * k / 48.0)
		points.append(center + dir * radius)
		uvs.append(Vector2(0.5, 0.5) + dir * 0.5)
	canvas.draw_polygon(points, PackedColorArray([tint]), uvs, texture)


static func label(font_size: int, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var node := Label.new()
	# Alegreya Sans se ve algo más pequeña que la fuente por defecto: se compensa.
	var final_size := font_size if font_size >= UiTheme.TITLE_SIZE else roundi(font_size * 1.1)
	node.add_theme_font_size_override("font_size", final_size)
	if font_size >= UiTheme.TITLE_SIZE:
		node.add_theme_font_override("font", UiTheme.title_font())
	node.add_theme_constant_override("outline_size", 6)
	node.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.85))
	node.horizontal_alignment = align
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


static func bar(fill: Color) -> ProgressBar:
	var node := ProgressBar.new()
	node.show_percentage = false
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.05, 0.05, 0.08, 0.8)
	var fill_box := StyleBoxFlat.new()
	fill_box.bg_color = fill
	node.add_theme_stylebox_override("background", background)
	node.add_theme_stylebox_override("fill", fill_box)
	return node


## Color de un arma según su primera etiqueta de elemento.
static func tag_color(tags: Array[StringName]) -> Color:
	for tag: StringName in tags:
		match tag:
			&"fuego":
				return Color(0.95, 0.5, 0.2)
			&"hielo":
				return Color(0.4, 0.75, 1.0)
			&"rayo":
				return Color(1.0, 0.88, 0.3)
			&"veneno":
				return Color(0.45, 0.85, 0.3)
			&"sombra":
				return Color(0.58, 0.36, 0.9)
			&"luz":
				return Color(1.0, 0.95, 0.7)
			&"fisico":
				return Color(0.62, 0.6, 0.66)
	return Color(0.5, 0.5, 0.55)


static func dim_background() -> ColorRect:
	var node := ColorRect.new()
	node.color = Color(0.02, 0.01, 0.01, 0.74)
	node.set_anchors_preset(Control.PRESET_FULL_RECT)
	return node
