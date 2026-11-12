extends Node
## Datos de la sesión actual entre escenas (menú → partida → menú).

const MENU_SCENE := "res://scenes/menu/main_menu.tscn"
const RUN_SCENE := "res://scenes/run/run.tscn"

## Campeón elegido en el menú.
var selected_champion: StringName = &"orrun"


var _theme: Theme


func _ready() -> void:
	# Tema global de la interfaz (marcos pintados, colores de texto).
	_theme = UiTheme.build()
	# Fuente por defecto también para lo que se dibuja a mano (HUD, cartas...).
	ThemeDB.fallback_font = UiTheme.body_font()
	get_tree().root.theme = _theme
	# Los controles colgados de una CanvasLayer no heredan el tema de la ventana:
	# se lo damos al aparecer (paneles de la partida, HUD...).
	get_tree().node_added.connect(_on_node_added)


func _on_node_added(node: Node) -> void:
	if node is Control and node.get_parent() is CanvasLayer and (node as Control).theme == null:
		(node as Control).theme = _theme


func start_run(champion_id: StringName) -> void:
	selected_champion = champion_id
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file(RUN_SCENE)


func go_to_menu() -> void:
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file(MENU_SCENE)
