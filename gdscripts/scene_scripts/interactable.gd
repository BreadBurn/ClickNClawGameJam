extends StaticBody3D

# Define a signal that passes the player node
signal interacted()

func on_interact(player: Node) -> void:
	print("INTERACT action acknowledged")
	# Emit the signal so other scripts can react
	interacted.emit()
