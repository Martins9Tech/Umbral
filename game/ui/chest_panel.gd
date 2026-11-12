class_name ChestPanel
extends CanvasLayer
## Panel que muestra qué ha dado un cofre.

signal closed

var _title: Label
var _body: Label
var _button: Button


func _ready() -> void:
	layer = 20
	visible = false
	add_child(UiStyle.dim_background())
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 20)
	center.add_child(box)
	_title = UiStyle.label(44, HORIZONTAL_ALIGNMENT_CENTER)
	_title.add_theme_color_override("font_color", Color(1.0, 0.82, 0.3))
	box.add_child(_title)
	_body = UiStyle.label(24, HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(_body)
	_button = Button.new()
	_button.text = "Continuar"
	_button.custom_minimum_size = Vector2(320.0, 60.0)
	_button.add_theme_font_size_override("font_size", 24)
	_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_button.pressed.connect(func() -> void:
		visible = false
		closed.emit())
	box.add_child(_button)


func open(lines: PackedStringArray) -> void:
	var is_evolution := not lines.is_empty() and lines[0].begins_with("EVOLUCIÓN")
	_title.text = "¡EVOLUCIÓN!" if is_evolution else "¡Cofre!"
	_body.text = "\n".join(lines)
	visible = true
	_button.grab_focus()
