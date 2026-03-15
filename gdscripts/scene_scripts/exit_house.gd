extends Node3D

# Assign this to a Node3D marker in the EXTERIOR scene (spawn point)
@export var exterior_spawn: Node3D

@onready var interactable: Node = $"../Interactable" if has_node("../Interactable") else $Interactable

func _ready() -> void:
	if interactable and interactable.has_signal("interacted"):
		if not interactable.interacted.is_connected(_on_interactable_interacted):
			interactable.interacted.connect(_on_interactable_interacted)
	else:
		push_warning("Interactable not found or missing 'interacted' signal")

func _on_interactable_interacted() -> void:
	print("exited house")
	
	SceneTransition.transition_in()
	await SceneTransition.transition_in_finished
	
	if not GameState.has_player():
		push_warning("No player registered in GameState")
		return

	if exterior_spawn == null:
		push_warning("No exterior_spawn assigned on HouseExitPortal")
		return

	GameState.teleport_player_to_node(exterior_spawn)

	# Optional: force facing after teleport
	if GameState.player is Player:
		(GameState.player as Player).set_facing(Player.Facing.DOWN)
		
	await get_tree().create_timer(0.25).timeout
	SceneTransition.transition_out()
