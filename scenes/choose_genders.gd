extends CanvasLayer

var level_scene: PackedScene = preload("res://scenes/level.tscn")

func _on_male_pressed() -> void:
	_select_gender_and_continue(true)

func _on_female_pressed() -> void:
	_select_gender_and_continue(false)

func _select_gender_and_continue(use_male: bool) -> void:
	# 1. Save the choice to your singleton
	GameState.is_player_male = use_male

	# 2. Move to the next scene
	get_tree().change_scene_to_packed(level_scene)
