class_name PauseMenu
extends CanvasLayer
## Menú de pausa visual: estadísticas en casillas (verde = mejorada), kit,
## armas con barra de daño y receta de evolución dibujada (arma + reliquia =
## evolución), y reliquias. Las descripciones largas van en tooltips.

signal resume_requested
signal restart_requested
signal settings_requested
signal menu_requested

const GOLD := Color(1.0, 0.82, 0.3)
const GREEN := Color(0.48, 0.9, 0.55)
const RED := Color(1.0, 0.55, 0.48)
const DIM := Color(0.68, 0.63, 0.57)
const CARD_BG := Color(0.1, 0.078, 0.062, 0.96)
const DAMAGE_BAR := Color(0.95, 0.55, 0.25)
const STAT_NAMES := {
	&"damage": "daño", &"cooldown": "enfriamiento", &"area": "área", &"move_speed": "velocidad",
	&"magnet": "imán", &"max_hp": "vida máx.", &"armor": "armadura", &"regen": "regeneración",
	&"xp_gain": "experiencia", &"amount": "cantidad", &"crit_chance": "prob. crítico",
	&"crit_damage": "daño crítico", &"dash_cooldown": "recarga del Paso", &"damage_taken": "daño recibido",
	&"size": "tamaño",
}

var _subtitle: Label
var _content: VBoxContainer
var _scroll: ScrollContainer
var _resume_button: Button


func _ready() -> void:
	layer = 25
	visible = false
	add_child(UiStyle.dim_background())
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 150)
	margin.add_theme_constant_override("margin_right", 150)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 40)
	add_child(margin)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiTheme.frame(40.0))
	margin.add_child(panel)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	panel.add_child(root)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 20)
	root.add_child(header)
	var title := UiStyle.label(38)
	title.text = "PAUSA"
	header.add_child(title)
	_subtitle = UiStyle.label(20)
	_subtitle.modulate = DIM
	_subtitle.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(_subtitle)
	var hint := UiStyle.label(16)
	hint.text = "Pasa el ratón por encima de algo para ver su descripción"
	hint.modulate = DIM
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(hint)

	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(_scroll)
	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 12)
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_content)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 24)
	root.add_child(buttons)
	_resume_button = _make_button("Continuar  (Esc)", func() -> void: resume_requested.emit())
	buttons.add_child(_resume_button)
	buttons.add_child(_make_button("Ajustes", func() -> void: settings_requested.emit()))
	buttons.add_child(_make_button("Reiniciar partida", func() -> void: restart_requested.emit()))
	buttons.add_child(_make_button("Salir al menú", func() -> void: menu_requested.emit()))


func open(run: Run) -> void:
	for child: Node in _content.get_children():
		_content.remove_child(child)
		child.queue_free()
	var player := run.player
	_subtitle.text = "%s   ·   Nivel %d   ·   %s   ·   %d muertes" % [
		player.kit.champion_name, run.level, run.time_text(), run.kills]
	_build_stats(player)
	_build_kit(player)
	_build_weapons(run, player)
	_build_synergies(player)
	_build_relics(player)
	_build_augments(player)
	_scroll.scroll_vertical = 0
	visible = true
	_resume_button.grab_focus()


func close() -> void:
	visible = false


# --- Secciones ---

func _build_stats(player: Player) -> void:
	_section("ESTADÍSTICAS", "Verde: mejorada respecto a la base del campeón")
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	_content.add_child(grid)
	var s := player.stats
	grid.add_child(_stat_tile("Vida", "%d / %d" % [ceili(player.hp), roundi(player.max_hp())],
		s.get_stat(StatId.MAX_HP) > s.get_base(StatId.MAX_HP), "Vida actual / máxima."))
	grid.add_child(_stat_tile("Armadura", str(roundi(s.get_stat(StatId.ARMOR))),
		s.get_stat(StatId.ARMOR) > s.get_base(StatId.ARMOR), "Reduce el daño recibido: daño × 100 / (100 + armadura)."))
	grid.add_child(_stat_tile("Regeneración", "%.1f /s" % s.get_stat(StatId.REGEN),
		s.get_stat(StatId.REGEN) > s.get_base(StatId.REGEN), "Vida recuperada por segundo."))
	grid.add_child(_stat_tile("Velocidad", "%.1f" % s.get_stat(StatId.MOVE_SPEED),
		s.get_stat(StatId.MOVE_SPEED) > s.get_base(StatId.MOVE_SPEED), "Velocidad de movimiento."))
	grid.add_child(_stat_tile("Imán", "%.1f m" % s.get_stat(StatId.MAGNET),
		s.get_stat(StatId.MAGNET) > s.get_base(StatId.MAGNET), "Radio al que atraes las gemas de experiencia."))
	grid.add_child(_stat_tile("Daño", _percent(s.get_stat(StatId.DAMAGE)),
		s.get_stat(StatId.DAMAGE) > 1.0, "Multiplica el daño de armas y habilidades."))
	grid.add_child(_stat_tile("Área", _percent(s.get_stat(StatId.AREA)),
		s.get_stat(StatId.AREA) > 1.0, "Tamaño de los ataques y las habilidades."))
	grid.add_child(_stat_tile("Enfriamiento", _percent(s.get_stat(StatId.COOLDOWN)),
		s.get_stat(StatId.COOLDOWN) < 1.0, "Tiempo entre disparos y habilidades (negativo = más rápido)."))
	grid.add_child(_stat_tile("Experiencia", _percent(s.get_stat(StatId.XP_GAIN)),
		s.get_stat(StatId.XP_GAIN) > 1.0, "Experiencia extra por gema."))
	grid.add_child(_stat_tile("Crítico", "%d %%  ·  x%.1f" % [roundi(s.get_stat(StatId.CRIT_CHANCE) * 100.0), s.get_stat(StatId.CRIT_DAMAGE)],
		s.get_stat(StatId.CRIT_CHANCE) > s.get_base(StatId.CRIT_CHANCE) or s.get_stat(StatId.CRIT_DAMAGE) > s.get_base(StatId.CRIT_DAMAGE),
		"Probabilidad de crítico y multiplicador de su daño."))


func _build_kit(player: Player) -> void:
	var kit := player.kit
	_section("KIT DEL CAMPEÓN")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	_content.add_child(row)
	row.add_child(_kit_card("RASGO · pasiva", kit.trait_name, 0, 0, kit.trait_description))
	row.add_child(_kit_card("TÉCNICA · Clic dcho / Q", kit.technique_name, kit.technique_rank,
		ChampionKit.MAX_TECHNIQUE_RANK, kit.technique_description))
	row.add_child(_kit_card("DEFINITIVA · R", kit.ultimate_name, kit.ultimate_rank,
		ChampionKit.MAX_ULTIMATE_RANK, kit.ultimate_description))


func _build_weapons(run: Run, player: Player) -> void:
	_section("ARMAS", "%d/%d huecos + arma de firma" % [Player.WEAPON_SLOTS - player.free_weapon_slots(), Player.WEAPON_SLOTS])
	var top_damage := 1.0
	for weapon: Weapon in player.weapons:
		top_damage = maxf(top_damage, float(player.damage_by_source.get(weapon.data.id, 0.0)))
	for weapon: Weapon in player.weapons:
		_content.add_child(_weapon_card(run, player, weapon, top_damage))


func _build_synergies(player: Player) -> void:
	_section("SINERGIAS", "Lleva 2 o 3 armas del mismo elemento")
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 10)
	flow.add_theme_constant_override("v_separation", 10)
	_content.add_child(flow)
	for tag: StringName in Synergies.DEFS:
		var amount := player.synergy_count(tag)
		var tier := player.synergy_tier(tag)
		var color := UiStyle.tag_color([tag])
		var card := _card(Vector2(420.0, 0.0), "", color if tier > 0 else Color(0.36, 0.29, 0.22))
		var box := VBoxContainer.new()
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(box)
		var title := "%s   ·   %d arma%s" % [Synergies.display_name(tag), amount, "" if amount == 1 else "s"]
		box.add_child(_text(title, 21, color if amount > 0 else DIM))
		for k in Synergies.TIERS.size():
			var active := tier > k
			var line := _text("%s  (%d)  %s" % ["ACTIVA" if active else "     ", Synergies.TIERS[k],
				Synergies.tier_description(tag, k + 1)], 15, GREEN if active else DIM)
			line.autowrap_mode = TextServer.AUTOWRAP_WORD
			line.custom_minimum_size = Vector2(390.0, 0.0)
			box.add_child(line)
		flow.add_child(card)


func _build_relics(player: Player) -> void:
	_section("RELIQUIAS", "%d/%d huecos" % [player.relic_levels.size(), Player.RELIC_SLOTS])
	if player.relic_levels.is_empty():
		var empty := UiStyle.label(18)
		empty.text = "Aún no tienes reliquias: aparecen como opción al subir de nivel."
		empty.modulate = DIM
		_content.add_child(empty)
		return
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 10)
	flow.add_theme_constant_override("v_separation", 10)
	_content.add_child(flow)
	for relic: RelicData in ContentDB.relics:
		var relic_level := player.relic_level(relic.id)
		if relic_level > 0:
			flow.add_child(_relic_card(relic, relic_level))


func _build_augments(player: Player) -> void:
	_section("AUMENTOS", "En los minutos 4 y 8 eliges uno de tres")
	if player.augments.is_empty():
		var empty := UiStyle.label(18)
		empty.text = "Aún no tienes aumentos: el primero llega en el minuto 4."
		empty.modulate = DIM
		_content.add_child(empty)
		return
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 10)
	flow.add_theme_constant_override("v_separation", 10)
	_content.add_child(flow)
	for augment: Augment in player.augments:
		var data := augment.data
		var color := AugmentData.rarity_color(data.rarity)
		var card := _card(Vector2(420.0, 0.0), data.description, color)
		var box := VBoxContainer.new()
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(box)
		box.add_child(_text(AugmentData.rarity_name(data.rarity), 15, color))
		box.add_child(_text(data.display_name, 22, Color.WHITE))
		var description := _text(data.description, 16, DIM)
		description.autowrap_mode = TextServer.AUTOWRAP_WORD
		description.custom_minimum_size = Vector2(380.0, 0.0)
		box.add_child(description)
		flow.add_child(card)


# --- Piezas ---

func _section(title: String, note: String = "") -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	var label := UiStyle.label(24)
	label.text = title
	label.add_theme_color_override("font_color", GOLD)
	row.add_child(label)
	if not note.is_empty():
		var note_label := UiStyle.label(16)
		note_label.text = note
		note_label.modulate = DIM
		note_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(note_label)
	_content.add_child(row)


func _card(min_size: Vector2, tooltip: String = "", border: Color = Color(0.36, 0.29, 0.22)) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = min_size
	card.add_theme_stylebox_override("panel", _box_style(CARD_BG, border, 1, 12.0))
	card.tooltip_text = tooltip
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	return card


func _stat_tile(stat_name: String, value: String, improved: bool, tooltip: String) -> PanelContainer:
	var card := _card(Vector2(220.0, 0.0), tooltip, GREEN if improved else Color(0.36, 0.29, 0.22))
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(box)
	box.add_child(_text(stat_name, 16, DIM))
	box.add_child(_text(value, 30, GREEN if improved else Color.WHITE))
	return card


func _kit_card(kind: String, ability_name: String, rank: int, max_rank: int, description: String) -> PanelContainer:
	var card := _card(Vector2(330.0, 0.0), description)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(box)
	box.add_child(_text(kind, 15, GOLD))
	box.add_child(_text(ability_name, 22, Color.WHITE))
	if max_rank > 0:
		var pips := HBoxContainer.new()
		pips.add_theme_constant_override("separation", 4)
		pips.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for k in max_rank:
			var pip := ColorRect.new()
			pip.custom_minimum_size = Vector2(28.0, 8.0)
			pip.color = Color(0.4, 0.8, 1.0) if k < rank else Color(1, 1, 1, 0.15)
			pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
			pips.add_child(pip)
		box.add_child(pips)
		box.add_child(_text("Rango %d / %d" % [rank, max_rank], 15, DIM))
	else:
		box.add_child(_text("Siempre activa", 15, DIM))
	return card


func _weapon_card(run: Run, player: Player, weapon: Weapon, top_damage: float) -> PanelContainer:
	var data := weapon.data
	var evolution_ready := weapon.can_evolve()
	var border := GOLD if weapon.is_evolved() or evolution_ready else Color(0.36, 0.29, 0.22)
	var card := _card(Vector2(0.0, 0.0), data.description, border)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(row)

	var slot := BuildSlot.new(72.0)
	slot.set_item(data.display_name, weapon.level, data.max_level, UiStyle.tag_color(data.tags),
		weapon.is_evolved(), evolution_ready, data.is_signature)
	slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(slot)

	# Nombre, nivel y daño
	var info := VBoxContainer.new()
	info.custom_minimum_size = Vector2(330.0, 0.0)
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(info)
	var title := data.display_name + ("  (firma)" if data.is_signature else "")
	info.add_child(_text(title, 22, GOLD if weapon.is_evolved() else Color.WHITE))
	var level_text := "EVOLUCIONADA" if weapon.is_evolved() else "Nivel %d / %d" % [weapon.level, data.max_level]
	info.add_child(_text(level_text, 16, GOLD if weapon.is_evolved() else DIM))
	var damage: float = player.damage_by_source.get(data.id, 0.0)
	var bar := UiStyle.bar(DAMAGE_BAR)
	bar.custom_minimum_size = Vector2(300.0, 10.0)
	bar.max_value = top_damage
	bar.value = damage
	info.add_child(bar)
	info.add_child(_text("%s de daño  ·  %d DPS" % [_short(damage), roundi(damage / maxf(run.elapsed, 1.0))], 15, DIM))

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(spacer)

	if data.evolution != null or weapon.is_evolved():
		row.add_child(_recipe(player, weapon))
	return card


## Receta dibujada: [arma] + [reliquia] = [evolución], y debajo qué falta.
func _recipe(player: Player, weapon: Weapon) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_text("EVOLUCIÓN", 14, DIM))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(row)

	var status := ""
	var status_color := RED
	if weapon.is_evolved():
		var done := BuildSlot.new(56.0)
		done.set_item(weapon.data.display_name, weapon.level, weapon.data.max_level, UiStyle.tag_color(weapon.data.tags), true)
		row.add_child(done)
		box.add_child(_text("Evolución completada", 15, GOLD))
		return box

	var data := weapon.data
	var weapon_slot := BuildSlot.new(56.0)
	weapon_slot.set_item(data.display_name, weapon.level, data.max_level, UiStyle.tag_color(data.tags))
	row.add_child(weapon_slot)
	row.add_child(_symbol("+"))
	var relic_name := UpgradeOffer.relic_display_name(data.evolution_relic)
	var relic_slot := BuildSlot.new(56.0)
	var relic_level := player.relic_level(data.evolution_relic)
	if relic_level > 0:
		relic_slot.set_item(relic_name, relic_level, 5, Hud.RELIC_COLOR)
	else:
		relic_slot.set_ghost(relic_name, Hud.RELIC_COLOR)
	row.add_child(relic_slot)
	row.add_child(_symbol("="))
	var result := BuildSlot.new(56.0)
	result.set_ghost(data.evolution.display_name, GOLD)
	row.add_child(result)

	var missing := PackedStringArray()
	if not weapon.is_max_level():
		missing.append("nivel %d" % data.max_level)
	if relic_level == 0:
		missing.append(relic_name)
	if missing.is_empty():
		status = "¡LISTA! Abre el cofre de una élite"
		status_color = GOLD
	else:
		status = "Falta: " + " y ".join(missing)
	box.add_child(_text(status, 15, status_color))
	box.add_child(_text("> " + data.evolution.display_name, 15, GOLD))
	return box


func _relic_card(relic: RelicData, relic_level: int) -> PanelContainer:
	var card := _card(Vector2(300.0, 0.0), relic.description)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(row)
	var slot := BuildSlot.new(60.0)
	slot.set_item(relic.display_name, relic_level, relic.max_level, Hud.RELIC_COLOR)
	row.add_child(slot)
	var info := VBoxContainer.new()
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(info)
	info.add_child(_text(relic.display_name, 20, Color.WHITE))
	info.add_child(_text(_relic_effect(relic, relic_level), 18, GREEN))
	info.add_child(_text("Nivel %d / %d" % [relic_level, relic.max_level], 15, DIM))
	return card


# --- Utilidades ---

func _text(value: String, font_size: int, color: Color) -> Label:
	var label := UiStyle.label(font_size)
	label.text = value
	label.add_theme_color_override("font_color", color)
	return label


func _symbol(value: String) -> Label:
	var label := _text(value, 26, DIM)
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return label


func _box_style(bg: Color, border: Color, border_width: int, padding: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(padding)
	return style


func _make_button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(300.0, 56.0)
	button.add_theme_font_size_override("font_size", 22)
	button.pressed.connect(action)
	return button


func _relic_effect(relic: RelicData, relic_level: int) -> String:
	var total := relic.value_per_level * relic_level
	var stat_name: String = STAT_NAMES.get(relic.stat, str(relic.stat))
	if relic.kind == Stats.Kind.FLAT:
		return "%+d %s" % [roundi(total), stat_name]
	return "%+d %% %s" % [roundi(total * 100.0), stat_name]


func _percent(multiplier: float) -> String:
	return "%+d %%" % roundi((multiplier - 1.0) * 100.0)


func _short(value: float) -> String:
	if value >= 1000.0:
		return "%.1fk" % (value / 1000.0)
	return str(roundi(value))
