extends Augment
## Cadena de Mando: cada muerte reduce 0,06 s el enfriamiento de la Técnica.


func on_kill(_p: Vector2, _flags: int) -> void:
	var kit := player.kit
	kit.technique_cooldown_left = maxf(0.0, kit.technique_cooldown_left - 0.06)
