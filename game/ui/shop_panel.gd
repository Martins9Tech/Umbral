class_name ShopPanel
extends CanvasLayer
## Tienda del mercader: cartas con precio en oro. Las que no puedes pagar
## salen apagadas; lo comprado queda como "Vendido".

signal buy_requested(index: int)
signal closed

const GOLD := Color(1.0, 0.82, 0.3)

var _gold_label: Label
var _grid: GridContainer
var _exit_button: Button


func _ready() -> void:
	layer = 22
	visible = false
	add_child(UiStyle.dim_background())
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	center.add_child(box)
	var title := UiStyle.label(44, HORIZONTAL_ALIGNMENT_CENTER)
	title.text = "MERCADER ERRANTE"
	title.add_theme_color_override("font_color", GOLD)
	box.add_child(UiTheme.titled(title))
	_gold_label = UiStyle.label(26, HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(_gold_label)
	_grid = GridContainer.new()
	_grid.columns = 3
	_grid.add_theme_constant_override("h_separation", 22)
	_grid.add_theme_constant_override("v_separation", 30)
	box.add_child(_grid)
	_exit_button = Button.new()
	_exit_button.text = "Salir de la tienda  (Esc)"
	_exit_button.custom_minimum_size = Vector2(360.0, 56.0)
	_exit_button.add_theme_font_size_override("font_size", 22)
	_exit_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_exit_button.pressed.connect(func() -> void: closed.emit())
	box.add_child(_exit_button)


func open(offers: Array[Dictionary], gold: int, sold: Array[bool]) -> void:
	_gold_label.text = "Tu oro: %d" % gold
	for child: Node in _grid.get_children():
		_grid.remove_child(child)
		child.queue_free()
	var first_focus: Button = null
	for k in offers.size():
		var offer := offers[k]
		var price: int = offer["price"]
		var is_sold := sold[k]
		var affordable := gold >= price and not is_sold
		var price_text := "VENDIDO" if is_sold else ("%d ORO" % price if gold >= price else "%d ORO · TE FALTA" % price)
		var card := _make_card(offer, k, price_text)
		card.disabled = not affordable
		card.pressed.connect(func() -> void: buy_requested.emit(k))
		_grid.add_child(card)
		card.appear(0.04 * k)
		if affordable and first_focus == null:
			first_focus = card
	visible = true
	(first_focus if first_focus != null else _exit_button).grab_focus()


const CARD_SIZE := Vector2(330.0, 330.0)


## Carta con el color de su categoría y el precio en la cinta.
func _make_card(offer: Dictionary, index: int, price_text: String) -> ChoiceCard:
	match offer["kind"]:
		&"upgrade":
			return ChoiceCard.from_upgrade(offer["option"], index, CARD_SIZE, price_text)
		&"augment":
			var data: AugmentData = offer["data"]
			var color := AugmentData.rarity_color(data.rarity)
			return ChoiceCard.create(&"aumento", index, data.display_name, AugmentData.rarity_name(data.rarity).to_upper(),
				data.description, color, price_text, color, "AUMENTO", CARD_SIZE, UiStyle.icon(data.id))
	return ChoiceCard.create(&"curacion", index, str(offer["title"]), "", str(offer["description"]),
		Color.TRANSPARENT, price_text, Color.TRANSPARENT, "", CARD_SIZE)


func close() -> void:
	visible = false


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := UiStyle.label(font_size)
	label.text = text
	label.add_theme_color_override("font_color", color)
	return label
