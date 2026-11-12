class_name UiTheme
## Tema global de la interfaz (se aplica a la ventana al arrancar): botones y
## paneles con los marcos pintados de piedra y bronce (art/ui), colores de
## texto cálidos y tooltips a juego. Si falta una textura, usa estilos planos.

const UI_DIR := "res://assets/ui/marcos/"
const FONT_DIR := "res://assets/fonts/"
## Tamaño a partir del cual un texto se considera título (va en Cinzel).
const TITLE_SIZE := 34

static var _body: Font
static var _bold: Font
static var _title: Font


## Texto general: Alegreya Sans (licencia OFL).
static func body_font() -> Font:
	if _body == null:
		_body = load(FONT_DIR + "AlegreyaSans-Regular.ttf")
	return _body


static func bold_font() -> Font:
	if _bold == null:
		_bold = load(FONT_DIR + "AlegreyaSans-Bold.ttf")
	return _bold


## Títulos: Cinzel en negrita (licencia OFL), de letra grabada en piedra.
static func title_font() -> Font:
	if _title == null:
		var variation := FontVariation.new()
		variation.base_font = load(FONT_DIR + "Cinzel.ttf")
		variation.variation_opentype = {"wght": 700}
		_title = variation
	return _title
const TEXT := Color(0.93, 0.89, 0.83)
const TEXT_HOVER := Color("ffd27a")
const TEXT_DISABLED := Color(0.55, 0.5, 0.46)
const AMBER := Color("ffae3d")

## Márgenes de 9 partes de cada textura (en píxeles de la textura).
const PANEL_MARGIN := 46.0
const BUTTON_MARGIN_X := 54.0
const BUTTON_MARGIN_Y := 24.0


static func build() -> Theme:
	var theme := Theme.new()
	theme.default_font = body_font()
	theme.default_font_size = 21
	theme.set_font("font", "Button", bold_font())
	var panel := frame()
	theme.set_stylebox("panel", "PanelContainer", panel)
	theme.set_stylebox("panel", "Panel", panel)
	var tooltip := StyleBoxFlat.new()
	tooltip.bg_color = Color(0.07, 0.055, 0.045, 0.97)
	tooltip.border_color = Color(AMBER, 0.6)
	tooltip.set_border_width_all(1)
	tooltip.set_corner_radius_all(6)
	tooltip.set_content_margin_all(10.0)
	theme.set_stylebox("panel", "TooltipPanel", tooltip)
	theme.set_color("font_color", "TooltipLabel", TEXT)

	for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		theme.set_stylebox(state, "Button", _button_style(state))
	theme.set_color("font_color", "Button", TEXT)
	theme.set_color("font_hover_color", "Button", TEXT_HOVER)
	theme.set_color("font_focus_color", "Button", TEXT_HOVER)
	theme.set_color("font_pressed_color", "Button", AMBER)
	theme.set_color("font_disabled_color", "Button", TEXT_DISABLED)
	theme.set_color("font_outline_color", "Button", Color(0, 0, 0, 0.85))
	theme.set_constant("outline_size", "Button", 4)
	theme.set_color("font_color", "Label", TEXT)
	theme.set_color("font_color", "CheckButton", TEXT)
	theme.set_color("font_hover_color", "CheckButton", TEXT_HOVER)
	return theme


## Panel con el marco pintado (para ventanas y menús).
static func frame(padding: float = 30.0) -> StyleBox:
	var texture := _texture("marco_panel")
	if texture == null:
		var flat := StyleBoxFlat.new()
		flat.bg_color = Color(0.07, 0.055, 0.045, 0.97)
		flat.border_color = Color(0.45, 0.35, 0.25)
		flat.set_border_width_all(2)
		flat.set_corner_radius_all(10)
		flat.set_content_margin_all(padding)
		return flat
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = PANEL_MARGIN
	style.texture_margin_right = PANEL_MARGIN
	style.texture_margin_top = PANEL_MARGIN
	style.texture_margin_bottom = PANEL_MARGIN
	style.set_content_margin_all(padding)
	return style


## Envuelve un título en la placa de piedra y bronce (centrada).
static func titled(label: Label) -> Control:
	var texture := _texture("placa_titulo")
	if texture == null:
		return label
	var plate := PanelContainer.new()
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = 120.0
	style.texture_margin_right = 120.0
	style.texture_margin_top = 56.0
	style.texture_margin_bottom = 56.0
	style.content_margin_left = 130.0
	style.content_margin_right = 130.0
	style.content_margin_top = 22.0
	style.content_margin_bottom = 26.0
	plate.add_theme_stylebox_override("panel", style)
	plate.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_child(label)
	return plate


static func _button_style(state: String) -> StyleBox:
	var texture := _texture("boton")
	if texture == null:
		var flat := StyleBoxFlat.new()
		flat.bg_color = Color(0.1, 0.08, 0.065, 0.95) if state != "hover" else Color(0.16, 0.12, 0.09, 0.98)
		flat.border_color = AMBER if state in ["hover", "focus"] else Color(0.45, 0.35, 0.25)
		flat.set_border_width_all(2)
		flat.set_corner_radius_all(8)
		flat.content_margin_left = 22.0
		flat.content_margin_right = 22.0
		flat.content_margin_top = 10.0
		flat.content_margin_bottom = 10.0
		return flat
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = BUTTON_MARGIN_X
	style.texture_margin_right = BUTTON_MARGIN_X
	style.texture_margin_top = BUTTON_MARGIN_Y
	style.texture_margin_bottom = BUTTON_MARGIN_Y
	style.content_margin_left = 62.0
	style.content_margin_right = 62.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	match state:
		"hover", "focus":
			style.modulate_color = Color(1.25, 1.12, 0.95)
		"pressed":
			style.modulate_color = Color(0.85, 0.8, 0.75)
		"disabled":
			style.modulate_color = Color(0.55, 0.52, 0.5, 0.8)
	return style


static func _texture(texture_name: String) -> Texture2D:
	var path := UI_DIR + texture_name + ".png"
	return load(path) if ResourceLoader.exists(path) else null
