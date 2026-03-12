extends Control
func _ready() -> void:
	Engine.time_scale = 1.0
func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")
func _on_quit_button_pressed() -> void:
	get_tree().quit()
