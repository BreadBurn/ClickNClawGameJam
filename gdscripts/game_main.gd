extends Node3D # Or whatever your Main scene root is

@onready var flora_container = $FloraContainer

func _ready() -> void:
	# Tell the GameState exactly where the container is
	GameState.register_flora_container(flora_container)
