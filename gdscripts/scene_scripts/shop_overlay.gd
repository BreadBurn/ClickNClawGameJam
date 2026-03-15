extends CanvasLayer

func _ready() -> void:
	# This runs exactly once when the game starts.
	# It ensures the shop is invisible before the player even sees it.
	hide()

func _on_button_pressed() -> void:
	# 1. Hide the entire CanvasLayer
	hide()
	
	# 2. Tell the GameState to unlock the player's controls
	GameState.end_interaction()
