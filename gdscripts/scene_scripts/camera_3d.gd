extends Camera3D

@export var target: Node3D

# Relative offsets from the target
@export var height_above_target := 6.5
@export var back_offset := 4.0        # along world +Z (adjust as you like)
@export var side_offset := 0.0        # along world +X

# Follow behavior
@export var follow_speed := 8.0       # lerp factor for normal movement
@export var snap_distance := 6.0      # if farther than this, snap instantly (covers teleports)

# Internals
var _initial_yaw_deg := 0.0

func _ready() -> void:
	# Cache the initial yaw and keep it forever (no Y-axis rotation).
	_initial_yaw_deg = rotation_degrees.y

func _physics_process(delta: float) -> void:
	if target == null:
		return

	# Build destination relative to the target using world axes (no rotation coupling).
	var up    := Vector3.UP * height_above_target
	var back  := Vector3(0, 0, back_offset)
	var side  := Vector3(side_offset, 0, 0)

	var destination := target.global_position + up + back + side

	# If target moved a lot (e.g., teleport), snap instantly; else smooth follow.
	if global_position.distance_to(destination) > snap_distance:
		global_position = destination
	else:
		# Exponential smoothing variant (frame-rate independent)
		var t := 1.0 - exp(-follow_speed * delta)
		global_position = global_position.lerp(destination, t)

	# Preserve original yaw; do not allow Y rotation changes.
	# (Keep current pitch/roll as-is; only lock the yaw.)
	var rot := rotation_degrees
	rot.y = _initial_yaw_deg
	rotation_degrees = rot
