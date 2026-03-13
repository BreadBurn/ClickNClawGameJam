extends Node
class_name InputComponent

@export var jump_buffer_time := 0.12
@export var interact_buffer_time := 0.20    # how long we remember an interact press
@export var interact_cooldown := 1.0        # seconds between interactions (anti-spam)

var input_vec := Vector2.ZERO
var _jump_buffer := 0.0

var _interact_buffer := 0.0
var _interact_cooldown_timer := 0.0

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("IN_JUMP"):
		_jump_buffer = jump_buffer_time
	if event.is_action_pressed("IN_INTERACT"):
		# Buffer the interact press. Cooldown is checked when consuming.
		_interact_buffer = interact_buffer_time

func _physics_process(delta: float) -> void:
	# Movement vector sampled in physics step
	input_vec = Input.get_vector("IN_M_LEFT", "IN_M_RIGHT", "IN_M_UP", "IN_M_DOWN")

	# Countdown buffers and cooldowns
	if _jump_buffer > 0.0:
		_jump_buffer -= delta

	if _interact_buffer > 0.0:
		_interact_buffer -= delta

	if _interact_cooldown_timer > 0.0:
		_interact_cooldown_timer -= delta

func consume_jump() -> bool:
	# One-shot read by the player in _physics_process
	if _jump_buffer > 0.0:
		_jump_buffer = 0.0
		return true
	return false

func consume_interact() -> bool:
	# Only allow interact if:
	# 1) there is a buffered press, and
	# 2) cooldown elapsed.
	if _interact_buffer > 0.0 and _interact_cooldown_timer <= 0.0:
		_interact_buffer = 0.0
		_interact_cooldown_timer = interact_cooldown  # start 1s cooldown
		return true
	return false
