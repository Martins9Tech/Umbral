class_name WeaponData
extends Resource
## Definición de un arma automática (GDD §5.2). El comportamiento vive en
## un script que extiende Weapon; aquí solo van los datos.

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var tags: Array[StringName] = []
@export var max_level: int = 8
## Arma de firma de un campeón: no aparece en el pool de subida de nivel.
@export var is_signature: bool = false
## Script que extiende Weapon e implementa el patrón de disparo.
@export var behaviour: GDScript

@export_group("Evolución")
## Reliquia necesaria: con el arma al nivel máximo, el siguiente cofre la evoluciona (GDD §5.4).
@export var evolution_relic: StringName
## Arma resultante de la evolución.
@export var evolution: WeaponData
## Esta arma ya es la versión evolucionada de otra.
@export var is_evolution: bool = false
