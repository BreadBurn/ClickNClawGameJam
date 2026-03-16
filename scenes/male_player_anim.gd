extends Node3D

@onready var sprite: AnimatedSprite3D = $AnimatedSprite3D

# Tracks the last horizontal direction used by the player.
# true = facing left, false = facing right
var _last_face_left: bool = false


func _ready() -> void:
	_update_visual()


func _physics_process(_delta: float) -> void:
	_update_visual()


func _update_visual() -> void:
	var player := GameState.player as Player
	if player == null or not is_instance_valid(player):
		return

	# --------------------------
	# Animation selection
	# --------------------------
	var desired_animation := "MaleMove"

	if player.state == Player.State.JUMP or player.state == Player.State.FALL:
		desired_animation = "MaleJump"
	elif player.state == Player.State.IDLE:
		desired_animation = "MaleIdle"
	else:
		desired_animation = "MaleMove"

	if sprite.animation != desired_animation:
		sprite.play(desired_animation)

	# --------------------------
	# Horizontal facing memory
	# Only update left/right when
	# the player is explicitly facing
	# left or right.
	# --------------------------
	match player.facing:
		Player.Facing.LEFT:
			_last_face_left = true
		Player.Facing.RIGHT:
			_last_face_left = false
		_:
			pass  # UP/DOWN keeps previous horizontal facing

	sprite.flip_h = _last_face_left
