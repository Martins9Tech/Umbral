class_name RelicData
extends Resource
## Reliquia pasiva de estadísticas (GDD §5.3).

@export var id: StringName
@export var display_name: String
@export var description: String
@export var stat: StringName
@export var kind: Stats.Kind = Stats.Kind.PERCENT
@export var value_per_level: float = 0.1
@export var max_level: int = 5
