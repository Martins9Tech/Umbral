extends Node
## Bus de eventos global (TECNICO §4.2). Los sistemas emiten aquí y quien
## necesite reaccionar (kits, aumentos, UI, logros) se conecta sin acoplarse.

@warning_ignore("unused_signal")
signal enemy_killed(type_index: int, position: Vector2, flags: int)
@warning_ignore("unused_signal")
signal player_damaged(player: Node, amount: float)
@warning_ignore("unused_signal")
signal level_up(new_level: int)
@warning_ignore("unused_signal")
signal ability_cast(caster: Node, ability_id: StringName)
@warning_ignore("unused_signal")
signal weapon_evolved(player: Node, weapon_name: String)
