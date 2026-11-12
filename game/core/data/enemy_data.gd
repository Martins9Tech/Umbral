class_name EnemyData
extends Resource
## Definición de un tipo de enemigo (GDD §8.1).

@export var id: StringName
@export var display_name: String
## Arquetipo de comportamiento: enjambre, corredor, bruto...
@export var archetype: StringName = &"enjambre"
@export var max_hp: float = 10.0
@export var speed: float = 3.0
@export var radius: float = 0.4
@export var height: float = 1.2
## Daño por segundo mientras toca al jugador.
@export var contact_dps: float = 10.0
@export var xp: int = 1
## Créditos que gasta el Director para generarlo.
@export var cost: float = 1.0
## Minuto a partir del cual puede aparecer.
@export var min_minute: float = 0.0
## Peso relativo al elegir qué enemigo generar.
@export var weight: float = 1.0
@export var color: Color = Color(0.8, 0.2, 0.2)
## Arte 2D: res://assets/sprites/enemigos/<id>.png. Altura del dibujo en metros
## y animación procedural: salto, galope o balanceo.
@export var sprite_height: float = 1.3
@export var anim: StringName = &"salto"
