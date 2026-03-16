extends Camera3D

func _ready() -> void:
	if DayRecap != null and DayRecap.has_method("set_main_camera"):
		DayRecap.set_main_camera(self)
