extends Node3D

func _on_interactable_interacted() -> void:
	GameState.go_to_sleep()
	DayRecap.activate_scene()
	
	print("INTERRACT SIGNAL received by SLEEP")
