extends Control

func _on_start_pressed() -> void:
	# get_tree().change_scene_to_file("res://scenes/game_main.tscn")
	# going to the level scene now!
	get_tree().change_scene_to_file("res://scenes/level.tscn")
