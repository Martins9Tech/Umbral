class_name AugmentData
extends Resource
## Aumento (GDD §5.5): mejora grande que se elige en momentos clave de la
## partida. Puede llevar modificadores de estadísticas y/o un comportamiento
## (script que extiende Augment) que reacciona a lo que pasa en la partida.

enum Rarity { ECO, ARCANO, MITICO }

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var rarity: Rarity = Rarity.ECO
@export_group("Estadísticas")
## Estadísticas que modifica (mismo orden en kinds y values).
@export var stats: Array[StringName] = []
## Tipo de cada modificador (Stats.Kind: 0 plano, 1 porcentaje, 2 multiplicador).
@export var kinds: Array[int] = []
@export var values: Array[float] = []
@export_group("Comportamiento")
## Script que extiende Augment (opcional).
@export var behaviour: GDScript


static func rarity_name(value: Rarity) -> String:
	match value:
		Rarity.ARCANO:
			return "ARCANO"
		Rarity.MITICO:
			return "MÍTICO"
	return "ECO"


static func rarity_color(value: Rarity) -> Color:
	match value:
		Rarity.ARCANO:
			return Color(1.0, 0.76, 0.25)
		Rarity.MITICO:
			return Color(0.88, 0.45, 1.0)
	return Color(0.72, 0.82, 0.92)
