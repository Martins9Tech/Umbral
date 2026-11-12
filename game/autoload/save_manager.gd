extends Node
## Progreso permanente y ajustes (TECNICO §4.2). El progreso va en
## user://save.json (versionado) y los ajustes en user://settings.cfg.
## Las pruebas automáticas no lo modifican nunca.

signal changed

const VERSION := 1
## Con el argumento --test-save se usa un guardado aparte (las pruebas no tocan el real).
var SAVE_PATH := "user://save.json"
var SETTINGS_PATH := "user://settings.cfg"
const DEFAULT_SETTINGS := {
	"volume": 0.8,
	"fullscreen": false,
	"vsync": true,
	"screen_shake": true,
	"vfx_intensity": 1.0,
}

var essence := 0
## Rango comprado de cada mejora de la Armería (clave: id en texto).
var armory: Dictionary = {}
var achievements: Array[String] = []
var stats := {"runs": 0, "wins": 0, "best_time": 0, "total_kills": 0}
var settings: Dictionary = DEFAULT_SETTINGS.duplicate()


func _ready() -> void:
	if OS.get_cmdline_user_args().has("--test-save"):
		SAVE_PATH = "user://save_test.json"
		SETTINGS_PATH = "user://settings_test.cfg"
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	load_game()
	load_settings()
	apply_settings()


# --- Progreso ---

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Partida guardada ilegible; se empieza de cero.")
		return
	var data: Dictionary = parsed
	essence = int(data.get("essence", 0))
	armory = data.get("armory", {})
	achievements.clear()
	for id: Variant in data.get("achievements", []):
		achievements.append(str(id))
	var saved_stats: Dictionary = data.get("stats", {})
	for key: String in stats:
		stats[key] = int(saved_stats.get(key, stats[key]))


func save_game() -> void:
	var data := {
		"version": VERSION, "essence": essence, "armory": armory,
		"achievements": achievements, "stats": stats,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data, "\t"))
	changed.emit()


func armory_rank(id: StringName) -> int:
	return int(armory.get(str(id), 0))


func buy_armory(id: StringName) -> bool:
	var entry := MetaContent.armory_entry(id)
	if entry.is_empty():
		return false
	var rank := armory_rank(id)
	if rank >= int(entry["max"]):
		return false
	var cost := MetaContent.armory_cost(entry, rank)
	if essence < cost:
		return false
	essence -= cost
	armory[str(id)] = rank + 1
	save_game()
	return true


## Devuelve toda la Esencia gastada en la Armería.
func refund_armory() -> void:
	for entry: Dictionary in MetaContent.ARMORY:
		for rank in armory_rank(entry["id"]):
			essence += MetaContent.armory_cost(entry, rank)
	armory.clear()
	save_game()


func has_achievement(id: StringName) -> bool:
	return achievements.has(str(id))


func is_weapon_unlocked(weapon_id: StringName) -> bool:
	var lock := MetaContent.weapon_lock(weapon_id)
	return lock.is_empty() or has_achievement(lock["id"])


## Registra una partida terminada: estadísticas, logros nuevos y Esencia.
## Devuelve {"essence": int, "new_achievements": Array[Dictionary]}.
func process_run(run_stats: Dictionary) -> Dictionary:
	stats["runs"] = int(stats["runs"]) + 1
	stats["total_kills"] = int(stats["total_kills"]) + int(run_stats["kills"])
	stats["best_time"] = maxi(int(stats["best_time"]), int(run_stats["seconds"]))
	if run_stats["victory"]:
		stats["wins"] = int(stats["wins"]) + 1
	var earned := MetaContent.essence_for(run_stats)
	var unlocked: Array[Dictionary] = []
	for achievement: Dictionary in MetaContent.ACHIEVEMENTS:
		if has_achievement(achievement["id"]):
			continue
		if _progress(achievement, run_stats) >= int(achievement["goal"]):
			achievements.append(str(achievement["id"]))
			earned += int(achievement["essence"])
			unlocked.append(achievement)
	essence += earned
	save_game()
	return {"essence": earned, "new_achievements": unlocked}


func _progress(achievement: Dictionary, run_stats: Dictionary) -> int:
	match achievement["check"]:
		&"runs":
			return int(stats["runs"])
		&"kills":
			return int(run_stats["kills"])
		&"evolutions":
			return int(run_stats["evolutions"])
		&"minutes":
			return int(run_stats["minutes"])
		&"synergy3":
			return 1 if int(run_stats["max_synergy"]) >= 3 else 0
		&"gold_spent":
			return int(run_stats["gold_spent"])
		&"victory":
			return 1 if run_stats["victory"] else 0
	return 0


## Truco de pruebas (F12 en el menú): todo desbloqueado y Esencia de sobra.
func debug_unlock_all() -> void:
	for achievement: Dictionary in MetaContent.ACHIEVEMENTS:
		if not has_achievement(achievement["id"]):
			achievements.append(str(achievement["id"]))
	essence += 5000
	save_game()


# --- Ajustes ---

func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	for key: String in DEFAULT_SETTINGS:
		settings[key] = config.get_value("ajustes", key, DEFAULT_SETTINGS[key])


func set_setting(key: String, value: Variant) -> void:
	settings[key] = value
	apply_settings()
	var config := ConfigFile.new()
	for setting_key: String in settings:
		config.set_value("ajustes", setting_key, settings[setting_key])
	config.save(SETTINGS_PATH)
	changed.emit()


func setting(key: String) -> Variant:
	return settings.get(key, DEFAULT_SETTINGS.get(key))


func apply_settings() -> void:
	var volume := clampf(float(setting("volume")), 0.0, 1.0)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(volume, 0.0001)))
	if DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if setting("fullscreen")
		else DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if setting("vsync")
		else DisplayServer.VSYNC_DISABLED)
