class_name Synergies
extends RefCounted
## Sinergias por elemento (GDD §5.6): tener 2 o 3 armas del mismo elemento
## (contando la de firma) activa bonus. Los efectos los consultan las armas y
## la partida a través de Player.

## Armas necesarias para cada nivel de sinergia.
const TIERS: Array[int] = [2, 3]
const DEFS := {
	&"fisico": {
		"name": "Físico",
		"tiers": ["+15 % de daño con armas físicas.", "+30 % de empuje y +15 % de área con armas físicas."],
	},
	&"fuego": {
		"name": "Fuego",
		"tiers": ["Las quemaduras hacen +50 % de daño y duran más.", "Los enemigos que mueren ardiendo explotan."],
	},
	&"hielo": {
		"name": "Hielo",
		"tiers": ["Ralentizas mucho más (-65 % de velocidad).", "Los golpes de hielo pueden congelar 1,5 s (congelados: +50 % de daño)."],
	},
	&"rayo": {
		"name": "Rayo",
		"tiers": ["+1 salto en las cadenas de rayos.", "Los rayos aturden 0,4 s y hacen +20 % de daño."],
	},
	&"sombra": {
		"name": "Sombra",
		"tiers": ["+12 % de probabilidad de crítico con armas de sombra.", "Las armas de sombra ejecutan a enemigos con menos del 12 % de vida."],
	},
}


static func is_element(tag: StringName) -> bool:
	return DEFS.has(tag)


static func display_name(tag: StringName) -> String:
	return DEFS[tag]["name"] if DEFS.has(tag) else str(tag)


static func tier_description(tag: StringName, tier: int) -> String:
	var tiers: Array = DEFS[tag]["tiers"]
	return tiers[tier - 1]


## Nivel de sinergia (0, 1 o 2) para un número de armas.
static func tier_for(amount: int) -> int:
	var tier := 0
	for k in TIERS.size():
		if amount >= TIERS[k]:
			tier = k + 1
	return tier


## Elementos de una lista de etiquetas.
static func elements_of(tags: Array[StringName]) -> Array[StringName]:
	var out: Array[StringName] = []
	for tag: StringName in tags:
		if is_element(tag):
			out.append(tag)
	return out
