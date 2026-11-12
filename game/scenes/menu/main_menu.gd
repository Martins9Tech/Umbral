extends Control
## Menú principal (GDD §6.1, versión de menú de La Encrucijada): jugar
## (selección de campeón), Armería, logros, ajustes y salir. Fondo: el
## bosque del moodboard. F12 = truco de pruebas (todo desbloqueado).

const BACKGROUND := preload("res://assets/ui/menu_fondo.png")
const PORTRAITS := {&"orrun": preload("res://assets/ui/orrun_retrato.png")}
const AMBER := Color("ffae3d")
const GOLD := Color(1.0, 0.82, 0.3)
const GREEN := Color(0.48, 0.9, 0.55)
const DIM := Color(0.68, 0.63, 0.57)
const CARD_BG := Color(0.1, 0.078, 0.062, 0.94)

var _panel: PanelContainer
var _content: VBoxContainer
var _essence_label: Label
var _stats_label: Label
var _toast: Label
var _toast_time := 0.0
var _settings: SettingsPanel
var _play_button: Button
var _capture_frame := 0


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.has("--metatest"):
		_run_meta_test()
		return
	if args.has("--autotest"):
		# Las pruebas automáticas van directas a la partida.
		GameSession.start_run.call_deferred(GameSession.selected_champion)
		return
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()
	SaveManager.changed.connect(_refresh_header)
	_refresh_header()
	_play_button.grab_focus()


func _process(delta: float) -> void:
	if OS.get_cmdline_user_args().has("--menu-capture"):
		# Recorre las pantallas para hacer capturas (con --test-save).
		_capture_frame += 1
		match _capture_frame:
			10:
				SaveManager.debug_unlock_all()
				SaveManager.buy_armory(&"vigor")
				SaveManager.buy_armory(&"poder")
			40:
				_show_champions()
			70:
				_show_armory()
			100:
				_show_achievements()
			130:
				_panel.visible = false
				_settings.open()
	if _toast_time > 0.0:
		_toast_time -= delta
		_toast.modulate.a = clampf(_toast_time, 0.0, 1.0)


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not (event as InputEventKey).pressed:
		return
	match (event as InputEventKey).physical_keycode:
		KEY_ESCAPE:
			if _panel.visible and not _settings.visible:
				_panel.visible = false
				_play_button.grab_focus()
		KEY_F12:
			SaveManager.debug_unlock_all()
			_show_toast("Truco: todo desbloqueado y +5.000 de Esencia.")
			if _panel.visible:
				_show_armory()


# --- Construcción ---

func _build() -> void:
	var background := TextureRect.new()
	background.texture = BACKGROUND
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.modulate = Color(0.55, 0.5, 0.5)
	add_child(background)
	var shade := ColorRect.new()
	shade.color = Color(0.04, 0.03, 0.03, 0.6)
	shade.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	shade.offset_right = 640.0
	add_child(shade)

	var left := VBoxContainer.new()
	left.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	left.offset_left = 80.0
	left.offset_right = 600.0
	left.offset_top = 120.0
	left.add_theme_constant_override("separation", 16)
	add_child(left)
	var title := UiStyle.label(110)
	title.text = "UMBRAL"
	title.add_theme_color_override("font_color", AMBER)
	left.add_child(title)
	var subtitle := UiStyle.label(22)
	subtitle.text = "Roguelike de supervivencia  ·  prototipo"
	subtitle.modulate = DIM
	left.add_child(subtitle)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0.0, 40.0)
	left.add_child(spacer)
	_play_button = _menu_button("Jugar", _show_champions)
	left.add_child(_play_button)
	left.add_child(_menu_button("Armería", _show_armory))
	left.add_child(_menu_button("Logros", _show_achievements))
	left.add_child(_menu_button("Ajustes", func() -> void: _settings.open()))
	left.add_child(_menu_button("Salir", func() -> void: get_tree().quit()))
	_stats_label = UiStyle.label(18)
	_stats_label.modulate = DIM
	left.add_child(_stats_label)

	_essence_label = UiStyle.label(30, HORIZONTAL_ALIGNMENT_RIGHT)
	_essence_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_essence_label.offset_left = -500.0
	_essence_label.offset_right = -40.0
	_essence_label.offset_top = 30.0
	_essence_label.add_theme_color_override("font_color", Color("b98cff"))
	add_child(_essence_label)

	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.offset_left = 700.0
	_panel.offset_right = -50.0
	_panel.offset_top = 90.0
	_panel.offset_bottom = -50.0
	_panel.add_theme_stylebox_override("panel", UiTheme.frame(40.0))
	_panel.visible = false
	add_child(_panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_panel.add_child(scroll)
	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 14)
	scroll.add_child(_content)

	_toast = UiStyle.label(22, HORIZONTAL_ALIGNMENT_CENTER)
	_toast.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_toast.offset_left = -500.0
	_toast.offset_right = 500.0
	_toast.offset_top = -70.0
	_toast.add_theme_color_override("font_color", GOLD)
	_toast.modulate.a = 0.0
	add_child(_toast)

	_settings = SettingsPanel.new()
	add_child(_settings)


func _refresh_header() -> void:
	_essence_label.text = "Esencia: %d" % SaveManager.essence
	var stats := SaveManager.stats
	var best := int(stats["best_time"])
	_stats_label.text = "Partidas %d   ·   Victorias %d   ·   Mejor tiempo %d:%02d" % [
		stats["runs"], stats["wins"], floori(best / 60.0), best % 60]


# --- Pantallas ---

func _open_panel(title: String, note: String) -> void:
	for child: Node in _content.get_children():
		_content.remove_child(child)
		child.queue_free()
	_panel.visible = true
	var header := UiStyle.label(40)
	header.text = title
	header.add_theme_color_override("font_color", AMBER)
	_content.add_child(header)
	if not note.is_empty():
		var note_label := UiStyle.label(18)
		note_label.text = note
		note_label.modulate = DIM
		note_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		_content.add_child(note_label)


func _show_champions() -> void:
	_open_panel("ELIGE CAMPEÓN", "Cada campeón cambia por completo la forma de jugar.")
	var first_button: Button = null
	for champion: Dictionary in MetaContent.CHAMPIONS:
		var locked := not str(champion["unlock"]).is_empty()
		var color: Color = champion["color"]
		var card := _card(color if not locked else Color(0.3, 0.3, 0.35))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 22)
		card.add_child(row)
		var portrait := TextureRect.new()
		portrait.custom_minimum_size = Vector2(200.0, 200.0)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if PORTRAITS.has(champion["id"]):
			portrait.texture = PORTRAITS[champion["id"]]
		else:
			portrait.modulate = Color(0.2, 0.2, 0.25)
		row.add_child(portrait)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_theme_constant_override("separation", 6)
		row.add_child(info)
		info.add_child(_text(str(champion["name"]), 36, color if not locked else DIM))
		info.add_child(_text("%s  ·  %s" % [champion["title"], champion["role"]], 18, DIM))
		var description := _text(str(champion["description"]), 18, Color(0.85, 0.85, 0.9))
		description.autowrap_mode = TextServer.AUTOWRAP_WORD
		info.add_child(description)
		var button := Button.new()
		button.custom_minimum_size = Vector2(300.0, 56.0)
		button.add_theme_font_size_override("font_size", 22)
		button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		if locked:
			button.text = "Bloqueado · próximamente"
			button.disabled = true
		else:
			button.text = "Empezar partida"
			var id: StringName = champion["id"]
			button.pressed.connect(func() -> void: GameSession.start_run(id))
			if first_button == null:
				first_button = button
		info.add_child(button)
		_content.add_child(card)
	var bonus := 0
	for entry: Dictionary in MetaContent.ARMORY:
		bonus += SaveManager.armory_rank(entry["id"])
	if bonus > 0:
		_content.add_child(_text("Mejoras de la Armería activas: %d rangos" % bonus, 18, Color("b98cff")))
	if first_button != null:
		first_button.grab_focus()


func _show_armory() -> void:
	_open_panel("ARMERÍA", "Mejoras permanentes para todas tus partidas. Se compran con Esencia, que ganas al terminar cada partida.")
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	_content.add_child(grid)
	for entry: Dictionary in MetaContent.ARMORY:
		var id: StringName = entry["id"]
		var rank := SaveManager.armory_rank(id)
		var max_rank: int = entry["max"]
		var cost := MetaContent.armory_cost(entry, rank)
		var maxed := rank >= max_rank
		var card := _card(GREEN if rank > 0 else Color(0.3, 0.3, 0.35))
		card.custom_minimum_size = Vector2(500.0, 0.0)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 6)
		card.add_child(box)
		box.add_child(_text(str(entry["name"]), 24, Color.WHITE))
		box.add_child(_text(str(entry["desc"]), 16, DIM))
		var pips := HBoxContainer.new()
		pips.add_theme_constant_override("separation", 4)
		for k in max_rank:
			var pip := ColorRect.new()
			pip.custom_minimum_size = Vector2(34.0, 9.0)
			pip.color = GREEN if k < rank else Color(1, 1, 1, 0.15)
			pips.add_child(pip)
		box.add_child(pips)
		var button := Button.new()
		button.add_theme_font_size_override("font_size", 18)
		button.custom_minimum_size = Vector2(240.0, 44.0)
		button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		if maxed:
			button.text = "MÁXIMO"
			button.disabled = true
		else:
			button.text = "Mejorar  ·  %d Esencia" % cost
			button.disabled = SaveManager.essence < cost
			button.pressed.connect(func() -> void:
				if SaveManager.buy_armory(id):
					_show_toast("%s mejorado." % entry["name"])
					_show_armory())
		box.add_child(button)
		grid.add_child(card)
	var refund := Button.new()
	refund.text = "Reembolsar toda la Esencia gastada"
	refund.add_theme_font_size_override("font_size", 18)
	refund.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	refund.pressed.connect(func() -> void:
		SaveManager.refund_armory()
		_show_toast("Esencia reembolsada.")
		_show_armory())
	_content.add_child(refund)


func _show_achievements() -> void:
	var done := 0
	for achievement: Dictionary in MetaContent.ACHIEVEMENTS:
		if SaveManager.has_achievement(achievement["id"]):
			done += 1
	_open_panel("LOGROS  ·  %d / %d" % [done, MetaContent.ACHIEVEMENTS.size()],
		"Se comprueban al terminar cada partida. Dan Esencia y algunos desbloquean armas nuevas.")
	for achievement: Dictionary in MetaContent.ACHIEVEMENTS:
		var got := SaveManager.has_achievement(achievement["id"])
		var card := _card(GREEN if got else Color(0.3, 0.3, 0.35))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 18)
		card.add_child(row)
		var state := _text("CONSEGUIDO" if got else "PENDIENTE", 16, GREEN if got else DIM)
		state.custom_minimum_size = Vector2(140.0, 0.0)
		row.add_child(state)
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		info.add_child(_text(str(achievement["name"]), 22, Color.WHITE if got else Color(0.85, 0.85, 0.9)))
		info.add_child(_text(str(achievement["desc"]), 16, DIM))
		var reward := "Recompensa: %d de Esencia" % int(achievement["essence"])
		var unlocks: StringName = achievement["unlocks"]
		if not str(unlocks).is_empty():
			var weapon := ContentDB.get_weapon(unlocks)
			reward += "  ·  Desbloquea el arma %s" % (weapon.display_name if weapon != null else str(unlocks))
		info.add_child(_text(reward, 16, GOLD))
		_content.add_child(card)


## Prueba de la progresión con un guardado aparte (usar con --test-save):
## partida ficticia → Esencia y logros → Armería → reembolso → recarga.
func _run_meta_test() -> void:
	var results := PackedStringArray()
	var weapon_locked_before := not SaveManager.is_weapon_unlocked(&"minas_de_brea")
	var outcome := SaveManager.process_run({
		"minutes": 10.5, "seconds": 630, "kills": 1200, "level": 30, "gold": 200,
		"gold_spent": 160, "victory": true, "evolutions": 1, "max_synergy": 3,
	})
	var names := PackedStringArray()
	for achievement: Dictionary in outcome["new_achievements"]:
		names.append(str(achievement["id"]))
	results.append("esencia_ganada=%d logros=%s" % [outcome["essence"], ",".join(names)])
	results.append("minas_bloqueada_antes=%s minas_ahora=%s guadana_ahora=%s" % [
		weapon_locked_before, SaveManager.is_weapon_unlocked(&"minas_de_brea"),
		SaveManager.is_weapon_unlocked(&"guadana_umbria")])
	var before := SaveManager.essence
	var bought := SaveManager.buy_armory(&"vigor")
	results.append("compra_vigor=%s rango=%d esencia %d->%d" % [bought, SaveManager.armory_rank(&"vigor"), before, SaveManager.essence])
	SaveManager.refund_armory()
	results.append("reembolso: rango=%d esencia=%d" % [SaveManager.armory_rank(&"vigor"), SaveManager.essence])
	var saved_essence := SaveManager.essence
	SaveManager.essence = 0
	SaveManager.load_game()
	results.append("recarga: esencia=%d (esperada %d) partidas=%d victorias=%d" % [
		SaveManager.essence, saved_essence, SaveManager.stats["runs"], SaveManager.stats["wins"]])
	for line: String in results:
		print("[META] ", line)
	get_tree().quit()


# --- Piezas ---

func _menu_button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(380.0, 64.0)
	button.add_theme_font_size_override("font_size", 28)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.pressed.connect(action)
	return button


func _card(border: Color) -> PanelContainer:
	var card := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = CARD_BG
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(16.0)
	card.add_theme_stylebox_override("panel", style)
	return card


func _text(value: String, font_size: int, color: Color) -> Label:
	var label := UiStyle.label(font_size)
	label.text = value
	label.add_theme_color_override("font_color", color)
	return label


func _show_toast(text: String) -> void:
	_toast.text = text
	_toast_time = 3.0
	_toast.modulate.a = 1.0
