extends Node

var selected_character : String = "VECTOR"
var game_mode : String = "normal"

func _ready() -> void:
	if not InputMap.has_action("ability"):
		InputMap.add_action("ability")
		var ev := InputEventKey.new()
		ev.physical_keycode = KEY_E
		InputMap.action_add_event("ability", ev)
