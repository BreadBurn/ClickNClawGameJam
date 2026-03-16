extends Node # (Or Node2D/Control, depending on what the parent is)

func _ready() -> void:
	# 1. Listen for the signal from the GameState
	GameState.reveal_furniture.connect(_on_reveal_furniture)

func _on_reveal_furniture() -> void:
	# 2. The exact names of the child nodes
	var furniture_names = ["RUG", "PAINTING", "DRAWER", "FISHCAT", "PAINTING2", "PIANO"]
	var hidden_furniture = []
	
	# 3. Look only at direct children and check if they are hidden
	for f_name in furniture_names:
		var node = get_node_or_null(f_name)
		if node and not node.visible:
			hidden_furniture.append(node)
			
	# 4. Pick a random one and make it visible
	if hidden_furniture.size() > 0:
		var random_item = hidden_furniture.pick_random()
		random_item.visible = true
		print("Revealed: ", random_item.name)
