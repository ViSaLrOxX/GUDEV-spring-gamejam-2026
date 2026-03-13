extends Control
func _ready() -> void:
	Engine.time_scale = 1.0
func _on_play_button_pressed() -> void:
	var gs = get_node_or_null("/root/GameState")
	if gs: gs.game_mode = "normal"
	get_tree().change_scene_to_file("res://scenes/character_select.tscn")
func _on_tutorial_button_pressed() -> void:
	var gs = get_node_or_null("/root/GameState")
	if gs: gs.game_mode = "tutorial"
	get_tree().change_scene_to_file("res://scenes/game.tscn")
func _on_range_button_pressed() -> void:
	var gs = get_node_or_null("/root/GameState")
	if gs: gs.game_mode = "range"
	get_tree().change_scene_to_file("res://scenes/game.tscn")
func _on_quit_button_pressed() -> void:
	get_tree().quit()
