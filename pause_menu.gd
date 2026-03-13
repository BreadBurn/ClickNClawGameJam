extends CanvasLayer

func _ready():
	hide()
	
func _input(event):
	if event.is_action_pressed("IN_PAUSE"):
		toggle_pause()

func toggle_pause():
	var is_paused = not get_tree().paused
	get_tree().paused = is_paused
	visible = is_paused

func _on_continue_btn_pressed() -> void:
	toggle_pause()


func _on_main_menu_btn_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://MainMenu.tscn")
