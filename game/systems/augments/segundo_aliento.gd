extends Augment
## Segundo Aliento: al bajar del 30 % de vida, se cura un 40 % (una vez).

var _used := false


func on_damaged(_amount: float) -> void:
	if _used or player.hp > player.max_hp() * 0.3:
		return
	_used = true
	player.heal(player.max_hp() * 0.4)
	run.vfx.disc(player.pos, 2.5, Color(0.4, 1.0, 0.5, 0.6), 0.6)
	run.notify_augment("¡Segundo Aliento! Te has curado un 40 %.")
