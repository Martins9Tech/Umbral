class_name PlayerInput
extends RefCounted
## Intención de un jugador en un frame (TECNICO §7.2). La simulación solo lee
## esto, nunca el teclado: en local se rellena con teclado, ratón o mando; en
## online la enviará cada cliente al anfitrión.

var move := Vector2.ZERO
var aim := Vector2(0.0, 1.0)
## Mantener la Técnica pulsada la relanza en cuanto está lista.
var technique_held := false
var ultimate_pressed := false
var dash_pressed := false


func clear_buttons() -> void:
	technique_held = false
	ultimate_pressed = false
	dash_pressed = false
