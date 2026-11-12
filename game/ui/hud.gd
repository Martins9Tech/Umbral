class_name Hud
extends CanvasLayer
## HUD del jugador local, construido por código (pasará a escena en la vertical slice).
## Arriba: nivel, vida, tiempo y muertes. Abajo en el centro: el kit.
## Abajo a la izquierda: armas y reliquias con su nivel.

const BUILD_SLOT_SIZE := 72.0
const RELIC_COLOR := Color(0.3, 0.72, 0.62)

var _xp_bar: HudWidgets.XpBar
var _player_frame: HudWidgets.PlayerFrame
var _time_label: Label
var _kills: HudWidgets.StatCounter
var _gold: HudWidgets.StatCounter
var _contract_label: Label
var _banner: Label
var _banner_time := 0.0
var _trait_slot: AbilitySlot
var _technique_slot: AbilitySlot
var _ultimate_slot: AbilitySlot
var _dash_slot: AbilitySlot
var _ultimate_was_ready := false
var _weapon_slots: Array[BuildSlot] = []
var _relic_slots: Array[BuildSlot] = []
var _augment_slots: Array[BuildSlot] = []
var _synergy_row: HBoxContainer
var _synergy_signature := ""
var _indicators: OffscreenIndicators
var _toast_box: VBoxContainer
var _toasts: Array[Dictionary] = []  # {node, time}
var _timeline_bar: TimelineBar
var _phase_label: Label
var _boss_box: VBoxContainer
var _boss_name: Label
var _boss_bar: ProgressBar
var _boss_markers: Control

const TOAST_TIME := 7.0
const MAX_TOASTS := 4


func _ready() -> void:
	layer = 5
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_indicators = OffscreenIndicators.new()
	root.add_child(_indicators)

	# Avisos: columna a la derecha con los momentos importantes.
	_toast_box = VBoxContainer.new()
	_toast_box.add_theme_constant_override("separation", 8)
	_toast_box.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	_toast_box.offset_left = -500.0
	_toast_box.offset_right = -16.0
	_toast_box.offset_top = 120.0
	_toast_box.offset_bottom = -260.0
	_toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_toast_box)

	_xp_bar = HudWidgets.XpBar.new()
	_xp_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_xp_bar.offset_bottom = 12.0
	root.add_child(_xp_bar)

	_player_frame = HudWidgets.PlayerFrame.new()
	_player_frame.position = Vector2(18.0, 22.0)
	_player_frame.portrait = load("res://assets/ui/orrun_retrato.png")
	root.add_child(_player_frame)

	_time_label = UiStyle.label(38, HORIZONTAL_ALIGNMENT_CENTER)
	_time_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_time_label.offset_left = -120.0
	_time_label.offset_right = 120.0
	_time_label.offset_top = 16.0
	_time_label.add_theme_constant_override("outline_size", 9)
	root.add_child(_time_label)

	# Línea de tiempo del mapa y fase actual (bajo el reloj)
	_timeline_bar = TimelineBar.new()
	_timeline_bar.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_timeline_bar.offset_left = -330.0
	_timeline_bar.offset_right = 330.0
	_timeline_bar.offset_top = 64.0
	_timeline_bar.offset_bottom = 90.0
	_timeline_bar.setup(MapTimeline.EVENTS, MapTimeline.BOSS_TIME)
	root.add_child(_timeline_bar)
	_phase_label = UiStyle.label(18, HORIZONTAL_ALIGNMENT_CENTER)
	_phase_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_phase_label.offset_left = -330.0
	_phase_label.offset_right = 330.0
	_phase_label.offset_top = 92.0
	root.add_child(_phase_label)

	# Barra del jefe (sustituye a la línea de tiempo durante el combate)
	_boss_box = VBoxContainer.new()
	_boss_box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_boss_box.offset_left = -460.0
	_boss_box.offset_right = 460.0
	_boss_box.offset_top = 60.0
	_boss_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_box.visible = false
	root.add_child(_boss_box)
	_boss_name = UiStyle.label(24, HORIZONTAL_ALIGNMENT_CENTER)
	_boss_name.add_theme_color_override("font_color", Color(0.6, 1.0, 0.45))
	_boss_box.add_child(_boss_name)
	_boss_bar = UiStyle.bar(Color(0.45, 0.85, 0.3))
	_boss_bar.custom_minimum_size = Vector2(920.0, 26.0)
	_boss_box.add_child(_boss_bar)
	_boss_markers = Control.new()
	_boss_markers.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_markers.set_anchors_preset(Control.PRESET_FULL_RECT)
	_boss_bar.add_child(_boss_markers)

	var counters := VBoxContainer.new()
	counters.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	counters.offset_left = -200.0
	counters.offset_right = -18.0
	counters.offset_top = 20.0
	counters.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(counters)
	_kills = HudWidgets.StatCounter.new(&"muertes", Color.WHITE)
	counters.add_child(_kills)
	_gold = HudWidgets.StatCounter.new(&"oro", HudWidgets.GOLD)
	counters.add_child(_gold)

	_contract_label = UiStyle.label(26, HORIZONTAL_ALIGNMENT_CENTER)
	_contract_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_contract_label.offset_left = -400.0
	_contract_label.offset_right = 400.0
	_contract_label.offset_top = 124.0
	_contract_label.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0))
	root.add_child(_contract_label)

	# Iconos del kit: Rasgo · Técnica · Definitiva · Paso
	var slots := HBoxContainer.new()
	slots.add_theme_constant_override("separation", 44)
	slots.alignment = BoxContainer.ALIGNMENT_CENTER
	slots.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	slots.offset_left = -360.0
	slots.offset_right = 360.0
	slots.offset_top = -190.0
	slots.offset_bottom = -20.0
	slots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(slots)
	_trait_slot = AbilitySlot.new("Pasiva", "", Color(0.78, 0.72, 0.66), 92.0, &"rasgo")
	_technique_slot = AbilitySlot.new("Q", "", Color(0.4, 0.8, 1.0), 120.0, &"tecnica")
	_ultimate_slot = AbilitySlot.new("R", "", Color(1.0, 0.72, 0.25), 132.0, &"definitiva")
	_dash_slot = AbilitySlot.new("Espacio", "Paso", Color(0.85, 0.88, 0.95), 84.0, &"paso")
	for slot: AbilitySlot in [_trait_slot, _technique_slot, _ultimate_slot, _dash_slot]:
		slot.size_flags_vertical = Control.SIZE_SHRINK_END
		slots.add_child(slot)

	# Build: armas (firma + 5) y reliquias (5)
	var build := VBoxContainer.new()
	build.add_theme_constant_override("separation", 6)
	build.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	build.offset_left = 16.0
	build.offset_right = 600.0
	build.offset_top = -350.0
	build.offset_bottom = -16.0
	build.alignment = BoxContainer.ALIGNMENT_END
	build.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(build)
	var hint := UiStyle.label(15)
	hint.text = "Esc: detalle de la build"
	hint.modulate.a = 0.7
	build.add_child(hint)
	build.add_child(_build_row(_weapon_slots, Player.WEAPON_SLOTS + 1, "Armas"))
	build.add_child(_build_row(_relic_slots, Player.RELIC_SLOTS, "Reliquias"))
	build.add_child(_build_row(_augment_slots, 4, "Aumentos"))
	_synergy_row = HBoxContainer.new()
	_synergy_row.add_theme_constant_override("separation", 6)
	_synergy_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	build.add_child(_synergy_row)

	_banner = UiStyle.label(34, HORIZONTAL_ALIGNMENT_CENTER)
	_banner.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_banner.offset_left = -500.0
	_banner.offset_right = 500.0
	_banner.offset_top = -235.0
	_banner.offset_bottom = -185.0
	_banner.add_theme_color_override("font_color", Color(1.0, 0.82, 0.3))
	_banner.visible = false
	root.add_child(_banner)


func _build_row(store: Array[BuildSlot], amount: int, title: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label := UiStyle.label(15)
	label.text = title
	label.custom_minimum_size = Vector2(76.0, 0.0)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)
	for _k in amount:
		var slot := BuildSlot.new(BUILD_SLOT_SIZE)
		row.add_child(slot)
		store.append(slot)
	return row


func _process(delta: float) -> void:
	if _banner_time > 0.0:
		_banner_time -= delta
		_banner.visible = _banner_time > 0.0
		_banner.modulate.a = clampf(_banner_time, 0.0, 1.0)
	for k in range(_toasts.size() - 1, -1, -1):
		var toast := _toasts[k]
		var time_left: float = toast["time"]
		time_left -= delta
		toast["time"] = time_left
		var node: Control = toast["node"]
		node.modulate.a = clampf(time_left, 0.0, 1.0)
		if time_left <= 0.0:
			node.queue_free()
			_toasts.remove_at(k)


## Aviso en la columna derecha (élites, cofres, evoluciones, consejos).
func notify(text: String, accent: Color = Color(1.0, 0.82, 0.3), duration: float = TOAST_TIME) -> void:
	while _toasts.size() >= MAX_TOASTS:
		var oldest: Control = _toasts[0]["node"]
		oldest.queue_free()
		_toasts.remove_at(0)
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.045, 0.04, 0.9)
	style.border_color = accent
	style.border_width_left = 5
	style.set_corner_radius_all(6)
	style.shadow_color = Color(0, 0, 0, 0.45)
	style.shadow_size = 6
	style.set_content_margin_all(12.0)
	panel.add_theme_stylebox_override("panel", style)
	var label := UiStyle.label(19)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.text = text
	panel.add_child(label)
	_toast_box.add_child(panel)
	_toasts.append({"node": panel, "time": duration})


## Progreso del contrato activo (vacío para ocultarlo).
func set_contract(text: String) -> void:
	_contract_label.text = text
	_contract_label.visible = not text.is_empty()


func set_indicators(world: Node2D, targets: Array[Dictionary]) -> void:
	_indicators.set_targets(world, targets)


func show_banner(text: String, duration: float = 2.0) -> void:
	_banner.text = text
	_banner_time = duration
	_banner.visible = true


func refresh(run: Run) -> void:
	var player := run.player
	_xp_bar.set_values(run.xp, run.xp_needed())
	_player_frame.set_values(run.level, player.hp, player.max_hp())
	_time_label.text = run.time_text()
	_kills.set_value(run.kills)
	_gold.set_value(run.gold)
	_refresh_timeline(run)

	_refresh_kit(player)
	_refresh_build(player)


func _refresh_timeline(run: Run) -> void:
	var boss := run.boss
	var fighting := boss != null and boss.is_alive()
	_boss_box.visible = fighting
	_timeline_bar.visible = not fighting
	_phase_label.visible = not fighting
	if fighting:
		_boss_name.text = "%s   ·   Fase %d / 3%s" % [boss.display_name, boss.phase,
			"   ·   ENFURECIDA" if boss.enraged else ""]
		_boss_bar.max_value = 1.0
		_boss_bar.value = boss.hp_fraction()
		_boss_bar.modulate = Color(1.6, 1.6, 1.6) if boss.state_name() != &"fighting" else Color.WHITE
		if _boss_markers.get_child_count() == 0:
			# Marcas de los umbrales de fase y del último aliento.
			for threshold: float in boss.phase_thresholds + [0.1]:
				var mark := ColorRect.new()
				mark.color = Color(1, 1, 1, 0.8)
				mark.size = Vector2(3.0, 26.0)
				mark.position = Vector2(920.0 * threshold - 1.5, 0.0)
				mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
				_boss_markers.add_child(mark)
		return
	_timeline_bar.set_progress(run.elapsed)
	var to_boss := MapTimeline.BOSS_TIME - run.elapsed
	if to_boss > 0.0:
		_phase_label.text = "Fase: %s   ·   Jefe en %d:%02d" % [run.timeline.phase_name(),
			floori(to_boss / 60.0), int(to_boss) % 60]
	else:
		_phase_label.text = "Fase: %s" % run.timeline.phase_name()


## Fichas de sinergia: elemento, armas que tienes / necesarias para el siguiente nivel.
func _refresh_synergies(player: Player) -> void:
	var signature := str(player.synergy_counts)
	if signature == _synergy_signature:
		return
	_synergy_signature = signature
	for child: Node in _synergy_row.get_children():
		_synergy_row.remove_child(child)
		child.queue_free()
	var title := UiStyle.label(15)
	title.text = "Sinergias"
	title.custom_minimum_size = Vector2(76.0, 0.0)
	_synergy_row.add_child(title)
	for tag: StringName in Synergies.DEFS:
		var amount := player.synergy_count(tag)
		if amount == 0:
			continue
		var tier := player.synergy_tier(tag)
		var color := UiStyle.tag_color([tag])
		var chip := PanelContainer.new()
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var style := StyleBoxFlat.new()
		style.bg_color = Color(color, 0.55 if tier > 0 else 0.18)
		style.border_color = color.lightened(0.3) if tier > 0 else Color(color, 0.5)
		style.set_border_width_all(2 if tier > 0 else 1)
		style.set_corner_radius_all(5)
		style.set_content_margin_all(6.0)
		chip.add_theme_stylebox_override("panel", style)
		var label := UiStyle.label(18)
		var next_needed: int = Synergies.TIERS[mini(tier, Synergies.TIERS.size() - 1)]
		label.text = "%s %d/%d" % [Synergies.display_name(tag), amount, next_needed] if tier < Synergies.TIERS.size() \
			else "%s MAX" % Synergies.display_name(tag)
		chip.add_child(label)
		_synergy_row.add_child(chip)


func _refresh_kit(player: Player) -> void:
	var kit := player.kit
	if _trait_slot.icon == null:
		_trait_slot.icon = UiStyle.icon(kit.trait_id)
		_technique_slot.icon = UiStyle.icon(kit.technique_id)
		_ultimate_slot.icon = UiStyle.icon(kit.ultimate_id)
		_dash_slot.icon = UiStyle.icon(&"paso")
	_trait_slot.title = kit.trait_name
	_trait_slot.set_state(kit.trait_fill(), kit.trait_fill() >= 1.0, kit.trait_text())

	var cooldown_max := maxf(kit.technique_cooldown_max(), 0.01)
	var technique_ready := kit.technique_cooldown_left <= 0.0
	_technique_slot.title = kit.technique_name
	_technique_slot.set_state(1.0 - kit.technique_cooldown_left / cooldown_max, technique_ready,
		"" if technique_ready else "%.1f" % kit.technique_cooldown_left)

	var ultimate_ready := kit.ultimate_ready() and not kit.ultimate_active()
	var ultimate_text := "%d%%" % int(kit.impetu / ChampionKit.IMPETU_MAX * 100.0)
	if kit.ultimate_active():
		ultimate_text = "ACTIVA"
	elif ultimate_ready:
		ultimate_text = ""
	elif kit.impetu_lockout_left > 0.0:
		ultimate_text = "%.0f s" % kit.impetu_lockout_left
	_ultimate_slot.title = kit.ultimate_name
	_ultimate_slot.set_state(1.0 if kit.ultimate_active() else kit.impetu / ChampionKit.IMPETU_MAX,
		ultimate_ready, ultimate_text, kit.ultimate_active())
	if ultimate_ready and not _ultimate_was_ready:
		show_banner("¡%s lista!  Pulsa R" % kit.ultimate_name)
	_ultimate_was_ready = ultimate_ready

	var dash_left := player.dash_cooldown_left
	_dash_slot.set_state(1.0 - dash_left / player.dash_cooldown_max(), dash_left <= 0.0,
		"" if dash_left <= 0.0 else "%.1f" % dash_left)


func _refresh_build(player: Player) -> void:
	for k in _weapon_slots.size():
		if k >= player.weapons.size():
			_weapon_slots[k].set_empty()
			continue
		var weapon := player.weapons[k]
		_weapon_slots[k].set_item(weapon.data.display_name, weapon.level, weapon.data.max_level,
			UiStyle.tag_color(weapon.data.tags), weapon.is_evolved(), weapon.can_evolve(),
			weapon.data.is_signature)
	var k := 0
	for relic: RelicData in ContentDB.relics:
		var relic_level := player.relic_level(relic.id)
		if relic_level == 0 or k >= _relic_slots.size():
			continue
		_relic_slots[k].set_item(relic.display_name, relic_level, relic.max_level, RELIC_COLOR)
		k += 1
	while k < _relic_slots.size():
		_relic_slots[k].set_empty()
		k += 1
	_refresh_synergies(player)
	for a in _augment_slots.size():
		if a < player.augments.size():
			var data := player.augments[a].data
			_augment_slots[a].set_badge(data.display_name, AugmentData.rarity_color(data.rarity),
				AugmentData.rarity_name(data.rarity))
		else:
			_augment_slots[a].set_empty()
