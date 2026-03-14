extends Node3D

@export var spawn_scene: PackedScene

@export_range(0.0, 1.0) var duplicate_chance: float = 0.5

@export var min_spawn_distance: float = 0.8
@export var max_spawn_distance: float = 2.5

func _ready() -> void:
	GameState.player_slept.connect(_on_player_slept)

func _on_player_slept(new_day: int) -> void:
	if randf() <= duplicate_chance:
		_multiply()

func _multiply() -> void:
	if spawn_scene == null:
		push_warning("Spawn scene is missing on ", name)
		return
		
	var new_flora: Node3D = spawn_scene.instantiate()
	get_parent().add_child(new_flora)
	
	var random_angle := randf() * TAU
	var random_distance := randf_range(min_spawn_distance, max_spawn_distance)
	
	var random_x := cos(random_angle) * random_distance
	var random_z := sin(random_angle) * random_distance
	
	var spawn_offset := Vector3(random_x, 0.0, random_z)
	new_flora.global_position = global_position + spawn_offset
