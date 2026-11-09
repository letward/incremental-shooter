extends Node

func _ready() -> void:
	_add_action("move_forward", KEY_W)
	_add_action("move_back", KEY_S)
	_add_action("move_left", KEY_A)
	_add_action("move_right", KEY_D)
	_add_action("jump", KEY_SPACE)
	_add_action("sprint", KEY_SHIFT)
	_add_action("shoot", 1) # MOUSE_BUTTON_LEFT
	_add_action("reload", KEY_R)
	_add_action("interact", KEY_E)
	_add_action("toggle_menu", KEY_TAB)
	_add_action("pause", KEY_ESCAPE)

func _add_action(action_name: String, key: int) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	var ev
	if key <= 10 and key >= 1:
		ev = InputEventMouseButton.new()
		ev.button_index = key
	else:
		ev = InputEventKey.new()
		ev.physical_keycode = key
	InputMap.action_add_event(action_name, ev)
