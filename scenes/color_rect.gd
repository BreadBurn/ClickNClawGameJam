extends ColorRect

# These signals let other scripts know when an animation finishes
signal transition_in_finished
signal transition_out_finished

@export var transition_duration: float = 1.0

func _ready():
	# Ensure the transition is hidden by default
	material.set_shader_parameter("outer_radius", 0.0)
	material.set_shader_parameter("inner_radius", 0.0)

# 1. Closes the circle (covers the screen in black)
func transition_in():
	material.set_shader_parameter("aspect_ratio", size.x / size.y)
	
	var tween = create_tween()
	tween.tween_property(material, "shader_parameter/outer_radius", 1.5, transition_duration)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_IN_OUT)
	
	# Emit the signal once the screen is fully black
	tween.tween_callback(func():
		transition_in_finished.emit()
	)

# 2. Opens the circle (reveals the new scene)
func transition_out():
	material.set_shader_parameter("aspect_ratio", size.x / size.y)
	
	var tween = create_tween()
	tween.tween_property(material, "shader_parameter/inner_radius", 1.5, transition_duration)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_IN_OUT)
		
	# Reset the shader and emit the final signal when done
	tween.tween_callback(func():
		material.set_shader_parameter("outer_radius", 0.0)
		material.set_shader_parameter("inner_radius", 0.0)
		transition_out_finished.emit()
	)
