extends Camera3D

@export var target: Node3D
@export var fixed_y_height := 6.645
@export var follow_speed := 8.0
var target_offset := 3.0

func _physics_process(delta: float) -> void:
	if not target:
		return
	
	var destination := Vector3(
		target.global_position.x,
		fixed_y_height,
		target.global_position.z + 4
	)
	
	global_position = global_position.lerp(destination, follow_speed * delta)
