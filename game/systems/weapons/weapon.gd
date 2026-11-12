class_name Weapon
extends Node2D
## Base de las armas automáticas (TECNICO §4.6): nodo ligero con temporizador.
## Cada arma concreta sobrescribe base_cooldown() y _fire() (o tick() si es
## continua, como las orbitales). Pertenece a un Player (champion).

var data: WeaponData
## Id del arma original (no cambia al evolucionar).
var base_id: StringName
var level := 1
var run: Run
var champion: Player
var _cooldown_left := 0.0


func setup(p_data: WeaponData, p_run: Run, p_champion: Player) -> void:
	data = p_data
	base_id = p_data.id
	run = p_run
	champion = p_champion
	_on_setup()


func level_up() -> void:
	level = mini(level + 1, data.max_level)
	_on_level_changed()


func is_evolved() -> bool:
	return data.is_evolution


func is_max_level() -> bool:
	return level >= data.max_level


func can_evolve() -> bool:
	return not is_evolved() and is_max_level() and data.evolution != null \
		and champion.relic_level(data.evolution_relic) > 0


func evolve(evolved_data: WeaponData) -> void:
	data = evolved_data
	level = data.max_level
	_on_level_changed()


func tick(delta: float) -> void:
	_cooldown_left -= delta
	if _cooldown_left > 0.0:
		return
	if _fire():
		_cooldown_left = base_cooldown() * champion.stats.get_stat(StatId.COOLDOWN)
	else:
		_cooldown_left = 0.1  # Sin objetivo: se reintenta enseguida.


# --- Para sobrescribir ---

func _on_setup() -> void:
	pass


func _on_level_changed() -> void:
	pass


func base_cooldown() -> float:
	return 1.0


## Devuelve true si ha disparado.
func _fire() -> bool:
	return false


# --- Ayudas ---

func dmg(base: float) -> float:
	return base * champion.stats.get_stat(StatId.DAMAGE) * champion.weapon_damage_mult(data.tags)


func area() -> float:
	return champion.stats.get_stat(StatId.AREA) * champion.weapon_area_mult(data.tags)


func extra_amount() -> int:
	return int(champion.stats.get_stat(StatId.AMOUNT))


func source_id() -> StringName:
	return data.id
