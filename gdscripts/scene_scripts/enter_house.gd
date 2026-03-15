extends Node3D

# Assign this in the inspector to a Node3D marker in the INTERIOR scene root
# If the interior is already instanced in the same world, set this to that interior's spawn marker.
# If you do cross-scene loading later, see the cross-scene variant below.
@export var interior_spawn: Node3D
@onready var interactable: Node = $"../Interactable" if has_node("../Interactable") else $Interactable

func _on_interactable_interacted() -> void:
	
	SceneTransition.transition_in()
	await SceneTransition.transition_in_finished
	
	if GameState.has_player():
		if interior_spawn:
			GameState.teleport_player_to_node(interior_spawn)
		else:
			push_warning("No interior_spawn assigned on HouseEntryPortal")
	else:
		push_warning("No player registered in GameState")
	
	await get_tree().create_timer(0.25).timeout
	SceneTransition.transition_out()
