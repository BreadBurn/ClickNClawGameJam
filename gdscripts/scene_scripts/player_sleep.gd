extends Node3D

func _on_interactable_interacted() -> void:
	GameState.go_to_sleep()
	print("INTERRACT SIGNAL received by SLEEP")
