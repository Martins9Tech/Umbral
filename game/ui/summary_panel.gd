class_name SummaryPanel
extends CanvasLayer
## Resumen al terminar la partida (GDD §10.3): victoria o derrota, tiempo,
## nivel, muertes, daño por fuente, Esencia ganada y logros nuevos.

signal retry_requested
signal menu_requested

const ESSENCE_COLOR := Color("b98cff")
const GOLD := Color(1.0, 0.82, 0.3)

var _title: Label
var _rewards: VBoxContainer
var _body: Label
var _retry: Button
var _menu: Button


func _ready() -> void:
	layer = 30
	visible = false
	add_child(UiStyle.dim_background())
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	center.add_child(box)
	_title = UiStyle.label(48, HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(_title)
	_rewards = VBoxContainer.new()
	_rewards.add_theme_constant_override("separation", 6)
	box.add_child(_rewards)
	_body = UiStyle.label(19)
	box.add_child(_body)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 20)
	box.add_child(buttons)
	_retry = _button(func() -> void: retry_requested.emit())
	buttons.add_child(_retry)
	_menu = _button(func() -> void: menu_requested.emit())
	_menu.text = "Volver al menú  (M)"
	buttons.add_child(_menu)


## meta: lo que devuelve SaveManager.process_run (vacío en pruebas automáticas).
func open(run: Run, victory: bool, saved_path: String = "", meta: Dictionary = {}) -> void:
	_title.text = "¡VICTORIA!  La Madre Raíz ha caído" if victory else "Has caído"
	_title.add_theme_color_override("font_color", Color(0.6, 1.0, 0.45) if victory else Color(1.0, 0.5, 0.45))
	_retry.text = "Jugar de nuevo  (R)" if victory else "Reintentar  (R)"

	for child: Node in _rewards.get_children():
		_rewards.remove_child(child)
		child.queue_free()
	if not meta.is_empty():
		_rewards.add_child(_line("+%d de Esencia  (total: %d)  ·  gástala en la Armería del menú" % [
			int(meta["essence"]), SaveManager.essence], 26, ESSENCE_COLOR))
		for achievement: Dictionary in meta["new_achievements"]:
			var text := "¡Logro! %s  (+%d de Esencia)" % [achievement["name"], int(achievement["essence"])]
			var unlocks: StringName = achievement["unlocks"]
			if not str(unlocks).is_empty():
				var weapon := ContentDB.get_weapon(unlocks)
				text += "  ·  Nueva arma desbloqueada: %s" % (weapon.display_name if weapon != null else str(unlocks))
			_rewards.add_child(_line(text, 21, GOLD))

	var player := run.player
	var damage := player.damage_by_source
	var lines := PackedStringArray()
	lines.append("Campeón: %s" % player.kit.champion_name)
	lines.append("Tiempo: %s   ·   Nivel: %d   ·   Muertes: %d   ·   Oro: %d" % [run.time_text(), run.level, run.kills, run.gold_earned])
	if not victory and not str(player.last_damage_cause).is_empty():
		lines.append("Te ha derrotado: %s" % player.last_damage_cause)
	lines.append("")
	lines.append("Daño por fuente:")
	var total := 0.0
	for amount: float in damage.values():
		total += amount
	var sources: Array = damage.keys()
	sources.sort_custom(func(a: StringName, b: StringName) -> bool:
		return float(damage[a]) > float(damage[b]))
	for source: StringName in sources.slice(0, 8):
		var amount: float = damage[source]
		var share := amount / total * 100.0 if total > 0.0 else 0.0
		lines.append("   %s:  %d  (%d %%,  %d DPS)" % [
			run.display_name_for(source, player), roundi(amount), roundi(share), roundi(amount / maxf(run.elapsed, 1.0))])
	if not saved_path.is_empty():
		lines.append("")
		lines.append("Partida registrada en: %s" % saved_path)
	_body.text = "\n".join(lines)
	visible = true
	_retry.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	match key_event.physical_keycode:
		KEY_R:
			get_viewport().set_input_as_handled()
			retry_requested.emit()
		KEY_M:
			get_viewport().set_input_as_handled()
			menu_requested.emit()


func _button(action: Callable) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(320.0, 56.0)
	button.add_theme_font_size_override("font_size", 22)
	button.pressed.connect(action)
	return button


func _line(text: String, font_size: int, color: Color) -> Label:
	var label := UiStyle.label(font_size, HORIZONTAL_ALIGNMENT_CENTER)
	label.text = text
	label.add_theme_color_override("font_color", color)
	return label
