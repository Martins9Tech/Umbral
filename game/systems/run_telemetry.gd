class_name RunTelemetry
extends RefCounted
## Registro de cada partida (TECNICO §4.9): al terminar se guarda un JSON en
## user://telemetry con el resultado, la build, el daño por fuente, las
## elecciones y una instantánea por minuto. tools/telemetry_report.py los resume.

const DIR := "user://telemetry"
const VERSION := 1

var snapshots: Array[Dictionary] = []
var choices: Array[Dictionary] = []
var _next_snapshot := 60.0


func tick(run: Run) -> void:
	if run.elapsed < _next_snapshot:
		return
	_next_snapshot += 60.0
	snapshots.append({
		"minuto": roundi(run.elapsed / 60.0), "nivel": run.level, "muertes": run.kills,
		"enemigos_vivos": run.swarm.count, "vida": roundi(run.player.hp), "oro": run.gold,
	})


func log_choice(elapsed: float, kind: StringName, what: String) -> void:
	choices.append({"t": roundi(elapsed), "tipo": str(kind), "que": what})


## Guarda la partida y devuelve la ruta absoluta del archivo ("" si falla).
func save(run: Run, result: String, mode: String) -> String:
	DirAccess.make_dir_recursive_absolute(DIR)
	var player := run.player
	var weapons: Array[Dictionary] = []
	for weapon: Weapon in player.weapons:
		weapons.append({"id": str(weapon.data.id), "nivel": weapon.level, "evolucionada": weapon.is_evolved()})
	var augments: Array[String] = []
	for augment: Augment in player.augments:
		augments.append(str(augment.data.id))
	var damage := {}
	for source: StringName in player.damage_by_source:
		damage[run.display_name_for(source, player)] = roundi(float(player.damage_by_source[source]))
	var boss_info := {}
	if run.boss != null:
		boss_info = {"fase": run.boss.phase, "vida_pct": roundi(run.boss.hp_fraction() * 100.0)}
	var data := {
		"version": VERSION,
		"fecha": Time.get_datetime_string_from_system(),
		"modo": mode,
		"semilla": run.run_seed,
		"campeon": player.kit.champion_name,
		"resultado": result,
		"tiempo_s": roundi(run.elapsed),
		"nivel": run.level,
		"muertes": run.kills,
		"oro_ganado": run.gold_earned,
		"oro_gastado": run.gold_spent,
		"causa_muerte": str(player.last_damage_cause) if result == "derrota" else "",
		"jefe": boss_info,
		"dano_por_fuente": damage,
		"armas": weapons,
		"reliquias": player.relic_levels.duplicate(),
		"aumentos": augments,
		"sinergias": player.synergy_counts.duplicate(),
		"elecciones": choices,
		"instantaneas": snapshots,
	}
	var stamp := Time.get_datetime_string_from_system().replace(":", "-")
	var path := "%s/partida_%s_%d.json" % [DIR, stamp, run.run_seed]
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return ""
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	return ProjectSettings.globalize_path(path)
