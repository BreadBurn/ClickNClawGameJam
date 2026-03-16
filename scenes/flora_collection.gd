extends Node3D

# Pick which flora this object gives in the Inspector:
# 0 = Plant 1
# 1 = Plant 2
# 2 = Plant 3
# 3 = Plant 4
@export_range(0, 3, 1) var flora_type: int = 0
@export var destroy_on_collect: bool = false

func _on_interactable_interacted() -> void:
	if GameState.try_pickup_plant(flora_type, 1):
		if destroy_on_collect:
			queue_free()
