class_name SettingsPanel
extends CanvasLayer
## Ajustes (GDD §11 accesibilidad): volumen, pantalla completa, VSync,
## temblor de cámara e intensidad de los efectos. Se guardan al momento.

signal closed

var _close_button: Button


func _ready() -> void:
	layer = 45
	visible = false
	add_child(UiStyle.dim_background())
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiTheme.frame(46.0))
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	box.custom_minimum_size = Vector2(640.0, 0.0)
	panel.add_child(box)

	var title := UiStyle.label(38, HORIZONTAL_ALIGNMENT_CENTER)
	title.text = "AJUSTES"
	title.add_theme_color_override("font_color", Color("ffae3d"))
	box.add_child(title)

	box.add_child(_slider_row("Volumen general", "volume", 0.0, 1.0))
	box.add_child(_check_row("Pantalla completa", "fullscreen"))
	box.add_child(_check_row("Sincronización vertical (VSync)", "vsync"))
	box.add_child(_check_row("Temblor de cámara", "screen_shake"))
	box.add_child(_slider_row("Intensidad de los efectos", "vfx_intensity", 0.2, 1.0))

	_close_button = Button.new()
	_close_button.text = "Volver"
	_close_button.custom_minimum_size = Vector2(260.0, 54.0)
	_close_button.add_theme_font_size_override("font_size", 22)
	_close_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_close_button.pressed.connect(func() -> void:
		visible = false
		closed.emit())
	box.add_child(_close_button)


func open() -> void:
	visible = true
	_close_button.grab_focus()


func _slider_row(text: String, key: String, min_value: float, max_value: float) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	var label := UiStyle.label(22)
	label.text = text
	label.custom_minimum_size = Vector2(320.0, 0.0)
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = 0.05
	slider.value = float(SaveManager.setting(key))
	slider.custom_minimum_size = Vector2(240.0, 32.0)
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var value_label := UiStyle.label(20)
	value_label.text = "%d %%" % roundi(slider.value * 100.0)
	slider.value_changed.connect(func(value: float) -> void:
		value_label.text = "%d %%" % roundi(value * 100.0)
		SaveManager.set_setting(key, value))
	row.add_child(slider)
	row.add_child(value_label)
	return row


func _check_row(text: String, key: String) -> Control:
	var check := CheckButton.new()
	check.text = text
	check.button_pressed = bool(SaveManager.setting(key))
	check.add_theme_font_size_override("font_size", 22)
	check.toggled.connect(func(pressed: bool) -> void: SaveManager.set_setting(key, pressed))
	return check
