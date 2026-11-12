extends Node
## Registra las acciones de entrada del juego. Se hace por código para el
## prototipo; más adelante se podrán reasignar desde los ajustes.

const DEADZONE := 0.25


func _ready() -> void:
	# Movimiento: WASD / flechas / stick izquierdo
	_keys(&"move_left", [KEY_A, KEY_LEFT])
	_keys(&"move_right", [KEY_D, KEY_RIGHT])
	_keys(&"move_up", [KEY_W, KEY_UP])
	_keys(&"move_down", [KEY_S, KEY_DOWN])
	_axis(&"move_left", JOY_AXIS_LEFT_X, -1.0)
	_axis(&"move_right", JOY_AXIS_LEFT_X, 1.0)
	_axis(&"move_up", JOY_AXIS_LEFT_Y, -1.0)
	_axis(&"move_down", JOY_AXIS_LEFT_Y, 1.0)

	# Apuntado con mando: stick derecho (con ratón se apunta al cursor)
	_axis(&"aim_left", JOY_AXIS_RIGHT_X, -1.0)
	_axis(&"aim_right", JOY_AXIS_RIGHT_X, 1.0)
	_axis(&"aim_up", JOY_AXIS_RIGHT_Y, -1.0)
	_axis(&"aim_down", JOY_AXIS_RIGHT_Y, 1.0)

	# Kit del campeón
	_keys(&"technique", [KEY_Q])
	_mouse(&"technique", MOUSE_BUTTON_RIGHT)
	_button(&"technique", JOY_BUTTON_RIGHT_SHOULDER)
	_keys(&"ultimate", [KEY_R])
	_axis(&"ultimate", JOY_AXIS_TRIGGER_RIGHT, 1.0)
	_keys(&"dash", [KEY_SPACE, KEY_SHIFT])
	_button(&"dash", JOY_BUTTON_A)

	# Sistema
	_keys(&"pause", [KEY_ESCAPE])
	_button(&"pause", JOY_BUTTON_START)

	# Depuración
	_keys(&"debug_overlay", [KEY_F1])
	_keys(&"debug_spawn", [KEY_F2])
	_keys(&"debug_god", [KEY_F3])
	_keys(&"debug_level", [KEY_F4])
	_keys(&"debug_time", [KEY_F5])
	_keys(&"debug_kill", [KEY_F6])
	_keys(&"debug_speed", [KEY_F7])
	_keys(&"debug_elite", [KEY_F8])
	_keys(&"debug_boss", [KEY_F9])
	_keys(&"debug_augment", [KEY_F10])


func _ensure(action: StringName) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, DEADZONE)


func _keys(action: StringName, keys: Array) -> void:
	_ensure(action)
	for key: int in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key as Key
		InputMap.action_add_event(action, event)


func _mouse(action: StringName, button: MouseButton) -> void:
	_ensure(action)
	var event := InputEventMouseButton.new()
	event.button_index = button
	InputMap.action_add_event(action, event)


func _button(action: StringName, button: JoyButton) -> void:
	_ensure(action)
	var event := InputEventJoypadButton.new()
	event.button_index = button
	InputMap.action_add_event(action, event)


func _axis(action: StringName, axis: JoyAxis, direction: float) -> void:
	_ensure(action)
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = direction
	InputMap.action_add_event(action, event)
