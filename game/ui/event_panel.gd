class_name EventPanel
extends CanvasLayer
## Panel de decisión de un evento del mapa (altar, contrato): título,
## explicación y dos botones, aceptar o rechazar.

signal decided(accepted: bool)

var _title: Label
var _body: Label
var _accept: Button
var _decline: Button


func _ready() -> void:
	layer = 22
	visible = false
	add_child(UiStyle.dim_background())
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 22)
	box.custom_minimum_size = Vector2(760.0, 0.0)
	center.add_child(box)
	_title = UiStyle.label(42, HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(_title)
	_body = UiStyle.label(24, HORIZONTAL_ALIGNMENT_CENTER)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD
	box.add_child(_body)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 24)
	box.add_child(buttons)
	_accept = _make_button(func() -> void: decided.emit(true))
	buttons.add_child(_accept)
	_decline = _make_button(func() -> void: decided.emit(false))
	buttons.add_child(_decline)


func open(title: String, body: String, accept_text: String, decline_text: String, color: Color) -> void:
	_title.text = title
	_title.add_theme_color_override("font_color", color)
	_body.text = body
	_accept.text = accept_text
	_decline.text = decline_text
	visible = true
	_accept.grab_focus()


func close() -> void:
	visible = false


func _make_button(action: Callable) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(320.0, 60.0)
	button.add_theme_font_size_override("font_size", 22)
	button.pressed.connect(action)
	return button
