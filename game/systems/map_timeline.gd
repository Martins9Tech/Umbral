class_name MapTimeline
extends RefCounted
## Línea de tiempo de un reino (GDD §6.4): fases con nombre y eventos
## programados (élites, Heraldo, estampida, jefe). Más adelante vendrá de
## MapData; de momento es la del Bosque de los Susurros.

const BOSS_TIME := 600.0
const PHASES := [
	{"start": 0.0, "name": "Llegada"},
	{"start": 120.0, "name": "Avance"},
	{"start": 240.0, "name": "Escalada"},
	{"start": 360.0, "name": "El Heraldo"},
	{"start": 480.0, "name": "Clímax"},
	{"start": 600.0, "name": "La Madre Raíz"},
]
## kind: elite, augment, altar, merchant, contract, herald, stampede, boss
const EVENTS := [
	{"time": 120.0, "kind": &"elite"},
	{"time": 180.0, "kind": &"altar"},
	{"time": 210.0, "kind": &"elite"},
	{"time": 240.0, "kind": &"augment"},
	{"time": 300.0, "kind": &"elite"},
	{"time": 330.0, "kind": &"merchant"},
	{"time": 360.0, "kind": &"herald"},
	{"time": 420.0, "kind": &"elite"},
	{"time": 450.0, "kind": &"contract"},
	{"time": 480.0, "kind": &"elite"},
	{"time": 480.0, "kind": &"augment"},
	{"time": 540.0, "kind": &"stampede"},
	{"time": 560.0, "kind": &"elite"},
	{"time": 600.0, "kind": &"boss"},
]

var phase_index := 0
var _next_event := 0


func tick(elapsed: float, run: Run) -> void:
	while phase_index + 1 < PHASES.size() and elapsed >= float(PHASES[phase_index + 1]["start"]):
		phase_index += 1
		run.on_phase_changed(phase_name())
	while _next_event < EVENTS.size() and elapsed >= float(EVENTS[_next_event]["time"]):
		var kind: StringName = EVENTS[_next_event]["kind"]
		_next_event += 1
		run.on_timeline_event(kind)


## Salta en el tiempo (trucos) sin disparar los eventos intermedios, salvo
## el del jefe si se ha alcanzado.
func skip_to(elapsed: float) -> void:
	while _next_event < EVENTS.size() and elapsed >= float(EVENTS[_next_event]["time"]) \
			and EVENTS[_next_event]["kind"] != &"boss":
		_next_event += 1


func phase_name() -> String:
	return PHASES[phase_index]["name"]


func events() -> Array:
	return EVENTS
