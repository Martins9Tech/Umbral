class_name LevelUpPanel
extends CanvasLayer
## Pantalla de subida de nivel: elegir 1 de 3 (teclas 1-3, ratón o mando).

signal chosen(index: int)

var _title: Label
var _subtitle: Label
var _row: HBoxContainer
var _buttons: Array[ChoiceCard] = []


func _ready() -> void:
	layer = 20
	visible = false
	add_child(UiStyle.dim_background())
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	center.add_child(box)
	_title = UiStyle.label(56, HORIZONTAL_ALIGNMENT_CENTER)
	_title.add_theme_color_override("font_color", Color("ffd34d"))
	_title.add_theme_constant_override("outline_size", 10)
	box.add_child(UiTheme.titled(_title))
	_subtitle = UiStyle.label(21, HORIZONTAL_ALIGNMENT_CENTER)
	_subtitle.text = "Elige una mejora  ·  teclas 1-3"
	_subtitle.modulate = Color(0.85, 0.8, 0.75)
	box.add_child(_subtitle)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0.0, 18.0)
	box.add_child(spacer)
	_row = HBoxContainer.new()
	_row.add_theme_constant_override("separation", 26)
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(_row)


func open(new_level: int, options: Array[Dictionary]) -> void:
	for button: ChoiceCard in _buttons:
		_row.remove_child(button)
		button.queue_free()
	_buttons.clear()
	_title.text = "¡NIVEL %d!" % new_level
	for k in options.size():
		var card := ChoiceCard.from_upgrade(options[k], k)
		card.pressed.connect(_on_pressed.bind(k))
		_row.add_child(card)
		card.appear(0.06 * k)
		_buttons.append(card)
	visible = true
	_title.pivot_offset = _title.size * 0.5
	_title.scale = Vector2.ONE * 1.4
	var tween := _title.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_title, "scale", Vector2.ONE, 0.3)
	if not _buttons.is_empty():
		_buttons[0].grab_focus()


func close() -> void:
	visible = false


func _on_pressed(index: int) -> void:
	chosen.emit(index)


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	var index := -1
	match key_event.physical_keycode:
		KEY_1, KEY_KP_1:
			index = 0
		KEY_2, KEY_KP_2:
			index = 1
		KEY_3, KEY_KP_3:
			index = 2
	if index >= 0 and index < _buttons.size():
		get_viewport().set_input_as_handled()
		chosen.emit(index)
