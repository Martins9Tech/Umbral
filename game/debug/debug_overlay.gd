class_name DebugOverlay
extends CanvasLayer
## Overlay de depuración (F1): rendimiento, contadores y trucos disponibles.

var _label: Label
var _sim_ms := 0.0


func _ready() -> void:
	layer = 40
	_label = UiStyle.label(16)
	_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_label.offset_left = -400.0
	_label.offset_right = -16.0
	_label.offset_top = 56.0
	add_child(_label)


func refresh(run: Run) -> void:
	if not visible:
		return
	_sim_ms = lerpf(_sim_ms, run.sim_usec / 1000.0, 0.05)
	var lines := PackedStringArray([
		"FPS: %d" % roundi(Engine.get_frames_per_second()),
		"Simulación: %.2f ms" % _sim_ms,
		"Enemigos: %d" % run.swarm.count,
		"Proyectiles: %d" % run.projectiles.count,
		"Gemas: %d" % run.gems.count,
		"Draw calls: %d" % roundi(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		"Director: min %.1f  ·  vida x%.2f" % [run.director.minute(), run.swarm.hp_scale],
		"Semilla: %d" % run.run_seed,
		"Modo dios: %s  ·  Velocidad x%.0f" % ["sí" if run.player.god_mode else "no", Engine.time_scale],
		"",
		"F1 overlay  ·  F2 +500 enemigos  ·  F3 modo dios",
		"F4 +1 nivel  ·  F5 +1 min  ·  F6 matar todo  ·  F7 x2",
		"F8 invocar una élite  ·  F9 saltar al jefe  ·  F10 aumento",
	])
	_label.text = "\n".join(lines)
