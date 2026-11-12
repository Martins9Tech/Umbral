class_name Augment
extends RefCounted
## Aumento activo de un jugador. Aplica los modificadores de su AugmentData y
## ofrece ganchos a los que reaccionar (TECNICO §4.5, versión ligera):
## tick, al golpear, al matar, al recibir daño y al usar una habilidad.

var data: AugmentData
var run: Run
var player: Player


func setup(p_data: AugmentData, p_run: Run, p_player: Player) -> void:
	data = p_data
	run = p_run
	player = p_player
	for k in data.stats.size():
		player.stats.add_modifier(data.stats[k], data.kinds[k] as Stats.Kind, data.values[k], data.id)
	_on_setup()


# --- Ganchos para sobrescribir ---

func _on_setup() -> void:
	pass


func tick(_delta: float) -> void:
	pass


## Tras dañar a un enemigo (amount ya incluye críticos).
func on_hit(_amount: float, _was_crit: bool) -> void:
	pass


func on_kill(_position: Vector2, _flags: int) -> void:
	pass


## Tras recibir daño (ya mitigado).
func on_damaged(_amount: float) -> void:
	pass


func on_ability_cast(_ability_id: StringName) -> void:
	pass
