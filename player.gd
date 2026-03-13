extends CharacterBody3D

enum State { IDLE, MOVE, JUMP, FALL, PERFORMING_ACTION, INTERACT }
enum Facing { UP, DOWN, LEFT, RIGHT }

var state: State = State.IDLE
var facing: Facing = Facing.DOWN

@export var speed := 5.0
@export var accel := 20.0
@export var decel := 30.0
@export var jump_velocity := 4.5
@export var floor_snap_len := 0.3

@export var interact_duration := 0.35
@export var interact_requires_ground := true

var gravity_y := ProjectSettings.get_setting("physics/3d/default_gravity") as float

var action_timer := 0.0
var jumped_this_frame := false
var interact_timer := 0.0

@onready var input: InputComponent = $UserControl
@onready var view_mesh: Node3D = $PlaceholderViewMesh
@onready var interact_area: Area3D = $InteractArea
@onready var debug_arrow: Node3D = $DEBUGNODEdirectionView

func _ready() -> void:
	motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED
	floor_snap_length = floor_snap_len
	up_direction = Vector3.UP

func _physics_process(delta: float) -> void:
	jumped_this_frame = false

	var raw_dir := Vector3(input.input_vec.x, 0, input.input_vec.y)
	var direction := raw_dir.normalized() if raw_dir.length() > 0.001 else Vector3.ZERO
	var grounded := is_on_floor()

	if _should_start_interact(grounded):
		_start_interact()
		_set_facing_if_needed(direction)
		velocity.x = move_toward(velocity.x, 0.0, decel * delta)
		velocity.z = move_toward(velocity.z, 0.0, decel * delta)
		if not grounded:
			velocity.y -= gravity_y * delta
		move_and_slide()
		_update_state(direction)
		return

	var should_jump := grounded and input.consume_jump()
	if should_jump and state != State.PERFORMING_ACTION and state != State.INTERACT:
		var prev_snap := floor_snap_length
		floor_snap_length = 0.0
		velocity.y = jump_velocity
		jumped_this_frame = true

		_set_facing_if_needed(direction)
		_apply_horizontal(direction, delta)
		move_and_slide()

		floor_snap_length = prev_snap
		_update_state(direction)
		return

	_apply_horizontal(direction, delta)

	if grounded:
		if velocity.y < 0.0:
			velocity.y = 0.0
	else:
		velocity.y -= gravity_y * delta

	_set_facing_if_needed(direction)
	move_and_slide()
	_update_state(direction)

func _should_start_interact(grounded: bool) -> bool:
	if state == State.PERFORMING_ACTION or state == State.INTERACT:
		return false
	if interact_requires_ground and not grounded:
		return false
	return input.consume_interact()

func _start_interact() -> void:
	state = State.INTERACT
	interact_timer = interact_duration

func _apply_horizontal(direction: Vector3, delta: float) -> void:
	match state:
		State.PERFORMING_ACTION, State.INTERACT:
			velocity.x = move_toward(velocity.x, 0.0, decel * delta)
			velocity.z = move_toward(velocity.z, 0.0, decel * delta)
			if state == State.PERFORMING_ACTION:
				action_timer -= delta
				if action_timer <= 0.0:
					state = State.IDLE
			elif state == State.INTERACT:
				interact_timer -= delta
				if interact_timer <= 0.0:
					state = State.IDLE
			return
		_:
			var target_vx := direction.x * speed
			var target_vz := direction.z * speed
			if direction != Vector3.ZERO:
				velocity.x = move_toward(velocity.x, target_vx, accel * delta)
				velocity.z = move_toward(velocity.z, target_vz, accel * delta)
			else:
				velocity.x = move_toward(velocity.x, 0.0, decel * delta)
				velocity.z = move_toward(velocity.z, 0.0, decel * delta)

func _set_facing_if_needed(direction: Vector3) -> void:
	if state != State.PERFORMING_ACTION and direction != Vector3.ZERO:
		_update_facing(direction)

func _update_state(direction: Vector3) -> void:
	if state == State.PERFORMING_ACTION or state == State.INTERACT:
		return

	if jumped_this_frame:
		state = State.JUMP
		return

	if is_on_floor():
		if absf(velocity.x) < 0.01 and absf(velocity.z) < 0.01:
			state = State.IDLE
		else:
			state = State.MOVE
	else:
		state = State.JUMP if (velocity.y > 0.0) else State.FALL

func _update_facing(dir: Vector3) -> void:
	if absf(dir.x) > absf(dir.z):
		if dir.x > 0:
			facing = Facing.RIGHT
			_set_y_rotation(0)
		else:
			facing = Facing.LEFT
			_set_y_rotation(-180)
	else:
		if dir.z > 0:
			facing = Facing.DOWN
			_set_y_rotation(-90)
		else:
			facing = Facing.UP
			_set_y_rotation(90)

func _set_y_rotation(degrees: float) -> void:
	$PlaceholderViewMesh.rotation_degrees.y = degrees
	$InteractArea.rotation_degrees.y = degrees
	$DEBUGNODEdirectionView.rotation_degrees.y = degrees

func perform_action() -> void:
	if state != State.PERFORMING_ACTION and is_on_floor():
		state = State.PERFORMING_ACTION
		action_timer = 0.5
