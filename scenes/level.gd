
extends Node3D # Or whatever your Main scene root is

@onready var flora_container = $FloraContainer

func _ready() -> void:
	# Tell the GameState exactly where the container is
	GameState.register_flora_container(flora_container)

	# Make sure gameplay is active again when returning to this scene
	if GameState != null:
		if GameState.has_method("end_interaction"):
			GameState.end_interaction()
		elif GameState.has_method("set_player_mode") and "PlayerMode" in GameState:
			GameState.set_player_mode(GameState.PlayerMode.PLAYER_ACTIVE)

	# Re-open the transition after the new scene has loaded
	await get_tree().process_frame
	if SceneTransition != null:
		SceneTransition.transition_out()
