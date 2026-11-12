extends Node
## Registro de contenido (TECNICO §4.2): carga los .tres de res://content por tipo.
## Añadir contenido = añadir un .tres; no hace falta tocar código.

const ENEMIES_DIR := "res://content/enemies"
const WEAPONS_DIR := "res://content/weapons"
const RELICS_DIR := "res://content/relics"
const AUGMENTS_DIR := "res://content/augments"

var enemies: Array[EnemyData] = []
var weapons: Array[WeaponData] = []
var relics: Array[RelicData] = []
var augments: Array[AugmentData] = []
var _tags_cache: Dictionary = {}
var _no_tags: Array[StringName] = []


func _ready() -> void:
	for res: Resource in _load_dir(ENEMIES_DIR):
		if res is EnemyData:
			enemies.append(res as EnemyData)
	enemies.sort_custom(func(a: EnemyData, b: EnemyData) -> bool: return a.cost < b.cost)

	for res: Resource in _load_dir(WEAPONS_DIR):
		if res is WeaponData:
			weapons.append(res as WeaponData)
	weapons.sort_custom(func(a: WeaponData, b: WeaponData) -> bool: return str(a.id) < str(b.id))

	for res: Resource in _load_dir(RELICS_DIR):
		if res is RelicData:
			relics.append(res as RelicData)
	relics.sort_custom(func(a: RelicData, b: RelicData) -> bool: return str(a.id) < str(b.id))

	for res: Resource in _load_dir(AUGMENTS_DIR):
		if res is AugmentData:
			augments.append(res as AugmentData)
	augments.sort_custom(func(a: AugmentData, b: AugmentData) -> bool: return str(a.id) < str(b.id))


## Etiquetas de una fuente de daño (arma); vacío si no es un arma.
func tags_of(source: StringName) -> Array[StringName]:
	if _tags_cache.is_empty():
		for weapon: WeaponData in weapons:
			_tags_cache[weapon.id] = weapon.tags
	if _tags_cache.has(source):
		return _tags_cache[source]
	return _no_tags


func get_weapon(id: StringName) -> WeaponData:
	for weapon: WeaponData in weapons:
		if weapon.id == id:
			return weapon
	return null


func _load_dir(path: String) -> Array[Resource]:
	var out: Array[Resource] = []
	for file: String in DirAccess.get_files_at(path):
		# En las builds exportadas los recursos aparecen como "*.tres.remap".
		var file_name := file.trim_suffix(".remap")
		if file_name.ends_with(".tres"):
			var res := load(path.path_join(file_name))
			if res != null:
				out.append(res)
	return out
