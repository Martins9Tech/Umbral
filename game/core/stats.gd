class_name Stats
extends RefCounted
## Bloque de estadísticas con modificadores (TECNICO §4.4).
## final = (base + Σ planos) × (1 + Σ porcentajes) × Π multiplicadores

enum Kind { FLAT, PERCENT, MULT }

var _base: Dictionary = {}
var _mods: Array[Dictionary] = []
var _cache: Dictionary = {}


func set_base(stat: StringName, value: float) -> void:
	_base[stat] = value
	_cache.clear()


func add_modifier(stat: StringName, kind: Kind, value: float, source: StringName) -> void:
	_mods.append({"stat": stat, "kind": kind, "value": value, "source": source})
	_cache.clear()


## Quita todos los modificadores de un origen (p. ej. una reliquia antes de subirla de nivel).
func remove_source(source: StringName) -> void:
	var kept: Array[Dictionary] = []
	for mod: Dictionary in _mods:
		if mod["source"] != source:
			kept.append(mod)
	_mods = kept
	_cache.clear()


func get_base(stat: StringName) -> float:
	return float(_base.get(stat, 0.0))


func get_stat(stat: StringName) -> float:
	if _cache.has(stat):
		return _cache[stat]
	var flat := 0.0
	var percent := 0.0
	var mult := 1.0
	for mod: Dictionary in _mods:
		if mod["stat"] != stat:
			continue
		var value: float = mod["value"]
		match mod["kind"]:
			Kind.FLAT:
				flat += value
			Kind.PERCENT:
				percent += value
			Kind.MULT:
				mult *= value
	var base: float = _base.get(stat, 0.0)
	var result := (base + flat) * (1.0 + percent) * mult
	_cache[stat] = result
	return result
