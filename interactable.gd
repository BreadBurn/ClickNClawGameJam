extends StaticBody3D

func on_interact(player: Node) -> void:
	print("INTERACTED with ", name, " by ", player.name)
