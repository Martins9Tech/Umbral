class_name AugmentPanel
extends CanvasLayer
## Elección de aumento: 3 cartas grandes con el color de su rareza y un
## recambio gratis (teclas 1-3 y T, ratón o mando).

signal chosen(index: int)
signal reroll_requested

var _title: Label
var _subtitle: Label
var _cards_box: HBoxContainer
var _reroll_button: Button
var _cards: Array[ChoiceCard] = []


func _ready() -> void:
	layer = 21
	visible = false
	add_child(UiStyle.dim_background())
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 22)
	center.add_child(box)
	_title = UiStyle.label(44, HORIZONTAL_ALIGNMENT_CENTER)
	_title.text = "¡AUMENTO!"
	_title.add_theme_color_override("font_color", Color(0.88, 0.45, 1.0))
	box.add_child(UiTheme.titled(_title))
	_subtitle = UiStyle.label(20, HORIZONTAL_ALIGNMENT_CENTER)
	_subtitle.text = "Elige una mejora poderosa para el resto de la partida"
	_subtitle.modulate = Color(0.8, 0.8, 0.88)
	box.add_child(_subtitle)
	_cards_box = HBoxContainer.new()
	_cards_box.add_theme_constant_override("separation", 22)
	_cards_box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(_cards_box)
	_reroll_button = Button.new()
	_reroll_button.custom_minimum_size = Vector2(380.0, 54.0)
	_reroll_button.add_theme_font_size_override("font_size", 20)
	_reroll_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_reroll_button.pressed.connect(func() -> void: reroll_requested.emit())
	box.add_child(_reroll_button)


func open(options: Array[AugmentData], rerolls_left: int) -> void:
	for card: ChoiceCard in _cards:
		_cards_box.remove_child(card)
		card.queue_free()
	_cards.clear()
	for k in options.size():
		var card := _make_card(k, options[k])
		_cards_box.add_child(card)
		card.appear(0.07 * k)
		_cards.append(card)
	_reroll_button.text = "Volver a tirar  (T)  ·  quedan %d" % rerolls_left
	_reroll_button.disabled = rerolls_left <= 0
	visible = true
	if not _cards.is_empty():
		_cards[0].grab_focus()


func close() -> void:
	visible = false


func _make_card(index: int, data: AugmentData) -> ChoiceCard:
	var color := AugmentData.rarity_color(data.rarity)
	var rarity := AugmentData.rarity_name(data.rarity).to_upper()
	var card := ChoiceCard.create(&"aumento", index, data.display_name, rarity, data.description, color,
		"", color, "AUMENTO · " + rarity, ChoiceCard.SIZE, UiStyle.icon(data.id))
	card.pressed.connect(func() -> void: chosen.emit(index))
	return card


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := UiStyle.label(font_size)
	label.text = text
	label.add_theme_color_override("font_color", color)
	return label


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	match key_event.physical_keycode:
		KEY_1, KEY_KP_1:
			_choose(0)
		KEY_2, KEY_KP_2:
			_choose(1)
		KEY_3, KEY_KP_3:
			_choose(2)
		KEY_T:
			if not _reroll_button.disabled:
				get_viewport().set_input_as_handled()
				reroll_requested.emit()


func _choose(index: int) -> void:
	if index < _cards.size():
		get_viewport().set_input_as_handled()
		chosen.emit(index)
