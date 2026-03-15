extends CanvasLayer

signal transition_in_finished
signal transition_out_finished

@export var transition_duration: float = 1.0

@onready var color_rect: ColorRect = $ColorRect

func _ready() -> void:
	color_rect.material.set_shader_parameter("outer_radius", 0.0)
	color_rect.material.set_shader_parameter("inner_radius", 0.0)

	# Prevent this full-screen UI from blocking mouse clicks
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

# 1. Closes the circle (covers the screen in black)
func transition_in():
	var aspect = color_rect.size.x / color_rect.size.y
	color_rect.material.set_shader_parameter("aspect_ratio", aspect)
	
	var tween = create_tween()
	tween.tween_property(color_rect.material, "shader_parameter/outer_radius", 1.5, transition_duration)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_IN_OUT)
	
	# Emit the signal once the screen is fully black
	tween.tween_callback(func():
		transition_in_finished.emit()
	)

# 2. Opens the circle (reveals the new scene)
func transition_out():
	var aspect = color_rect.size.x / color_rect.size.y
	color_rect.material.set_shader_parameter("aspect_ratio", aspect)
	
	var tween = create_tween()
	tween.tween_property(color_rect.material, "shader_parameter/inner_radius", 1.5, transition_duration)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_IN_OUT)
		
	# Reset the shader and emit the final signal when done
	tween.tween_callback(func():
		color_rect.material.set_shader_parameter("outer_radius", 0.0)
		color_rect.material.set_shader_parameter("inner_radius", 0.0)
		transition_out_finished.emit()
	)
