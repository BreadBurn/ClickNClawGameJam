extends Node
class_name InputComponent

var input_vec := Vector2.ZERO
var jump_just_pressed := false

func _process(delta: float) -> void:
	input_vec = Input.get_vector("IN_M_LEFT", "IN_M_RIGHT", "IN_M_UP", "IN_M_DOWN")
	jump_just_pressed = Input.is_action_just_pressed("IN_JUMP")
