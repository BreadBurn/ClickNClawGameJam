
extends CanvasLayer

func _ready() -> void:
	await get_tree().process_frame
	SceneTransition.transition_out()

func _on_button_pressed() -> void:
	SceneTransition.transition_in()
	await SceneTransition.transition_in_finished

	# Make sure gameplay is re-enabled before going back
	if GameState != null:
		if GameState.has_method("end_interaction"):
			GameState.end_interaction()
		elif GameState.has_method("set_player_mode") and "PlayerMode" in GameState:
			GameState.set_player_mode(GameState.PlayerMode.PLAYER_ACTIVE)

	get_tree().change_scene_to_file("res://scenes/level.tscn")
