extends Node3D

# Drag your Shop UI (CanvasLayer or Control) into this slot in the Inspector
@export var shop_ui: CanvasLayer 

func _on_interactable_interacted() -> void:
	print("IN")
	if shop_ui == null:
		push_warning("Shop UI is not assigned in the Inspector!")
		return
		
	# 1. Make the shop visible on screen
	shop_ui.show()
	
	# 2. Lock the player's movement and normal inputs
	GameState.begin_interaction()
