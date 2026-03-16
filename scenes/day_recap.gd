extends CanvasLayer

@onready var day_label: Label  = $"PanelContainer/MarginContainer/VBoxContainer/DayLabel"
@onready var gold_label: Label = $"PanelContainer/MarginContainer/VBoxContainer/GoldEarned"

@onready var progress_t1: ProgressBar = $"PanelContainer/MarginContainer/VBoxContainer/ProgressBarT1"
@onready var progress_t2: ProgressBar = $"PanelContainer/MarginContainer/VBoxContainer/ProgressBarT2"
@onready var progress_t3: ProgressBar = $"PanelContainer/MarginContainer/VBoxContainer/ProgressBarT3"
@onready var progress_t4: ProgressBar = $"PanelContainer/MarginContainer/VBoxContainer/ProgressBarT4"

@onready var sub_viewport: SubViewport = $PanelContainer/MarginContainer2/VBoxContainer/SubViewportContainer/SubViewport
@onready var preview_cam: Camera3D = $PanelContainer/MarginContainer2/VBoxContainer/SubViewportContainer/SubViewport/PreviewCamera

@onready var bars: Array[ProgressBar] = [progress_t1, progress_t2, progress_t3, progress_t4]

var _is_active: bool = false
var _is_transitioning: bool = false
var _should_load_win_scene: bool = false
var main_cam: Camera3D

func _ready() -> void:
	hide()
	_is_active = false
	_is_transitioning = false
	_should_load_win_scene = false

	if GameState != null and GameState.has_signal("daily_evaluated"):
		GameState.daily_evaluated.connect(_on_daily_evaluated)

	if GameState != null and GameState.has_signal("game_won"):
		GameState.game_won.connect(_on_game_won)

	set_process_input(true)

func set_main_camera(cam: Camera3D) -> void:
	main_cam = cam
	sub_viewport.world_3d = cam.get_viewport().world_3d

	preview_cam.projection = cam.projection
	preview_cam.near = cam.near
	preview_cam.far = cam.far
	preview_cam.keep_aspect = cam.keep_aspect

	if cam.projection == Camera3D.PROJECTION_PERSPECTIVE:
		preview_cam.fov = cam.fov
	elif cam.projection == Camera3D.PROJECTION_ORTHOGONAL:
		preview_cam.size = cam.size

func _process(_delta: float) -> void:
	if not is_instance_valid(main_cam):
		return

	# Copy transform
	preview_cam.global_transform = main_cam.global_transform

	# Copy projection mode
	preview_cam.projection = main_cam.projection

	# Copy shared camera settings
	preview_cam.near = main_cam.near
	preview_cam.far = main_cam.far
	preview_cam.keep_aspect = main_cam.keep_aspect

	# Copy the correct projection-specific setting
	if main_cam.projection == Camera3D.PROJECTION_PERSPECTIVE:
		preview_cam.fov = main_cam.fov
	elif main_cam.projection == Camera3D.PROJECTION_ORTHOGONAL:
		preview_cam.size = main_cam.size

func _on_daily_evaluated(coins_earned: int, _types_in_bounds: int, current_streak: int) -> void:
	_populate_from_state(coins_earned)

	var new_day := GameState.cur_day
	var old_day: int = max(new_day - 1, 0)
	day_label.text = "Day %d -> %d" % [old_day, new_day]

	# If this evaluation completes the 3-day streak,
	# remember to send the player to the win scene when they exit.
	_should_load_win_scene = current_streak >= 3

	activate_scene()

func _on_game_won() -> void:
	_should_load_win_scene = true

func _populate_from_state(coins_earned: int) -> void:
	var ratios: Dictionary = {}
	if GameState != null and "latest_ratios" in GameState:
		ratios = GameState.latest_ratios
	else:
		ratios = {0: 0.0, 1: 0.0, 2: 0.0, 3: 0.0}

	for i in range(4):
		var pct := clampf(float(ratios.get(i, 0.0)) * 100.0, 0.0, 100.0)

		if i < bars.size() and bars[i]:
			bars[i].min_value = 0.0
			bars[i].max_value = 100.0
			bars[i].value = pct

	if gold_label:
		gold_label.text = "+$%d" % coins_earned

func activate_scene() -> void:
	if _is_active or _is_transitioning:
		return

	_is_transitioning = true

	if GameState != null:
		if GameState.has_method("begin_interaction"):
			GameState.begin_interaction()
		elif GameState.has_method("set_player_mode") and "PlayerMode" in GameState:
			GameState.set_player_mode(GameState.PlayerMode.PLAYER_INACTIVE)

	SceneTransition.transition_in()
	await SceneTransition.transition_in_finished

	show()
	_is_active = true

	await get_tree().create_timer(0.25).timeout
	SceneTransition.transition_out()

	_is_transitioning = false


func deactivate_scene() -> void:
	if not _is_active or _is_transitioning:
		return

	_is_transitioning = true

	SceneTransition.transition_in()
	await SceneTransition.transition_in_finished

	# WIN BRANCH: restore player mode before leaving this scene
	if _should_load_win_scene or (GameState != null and GameState.consecutive_balanced_days >= 3):
		hide()
		_is_active = false

		if GameState != null:
			if GameState.has_method("end_interaction"):
				GameState.end_interaction()
			elif GameState.has_method("set_player_mode") and "PlayerMode" in GameState:
				GameState.set_player_mode(GameState.PlayerMode.PLAYER_ACTIVE)

		get_tree().change_scene_to_file("res://scenes/GameWon.tscn")
		return

	# NORMAL CLOSE
	hide()
	_is_active = false

	if GameState != null:
		if GameState.has_method("end_interaction"):
			GameState.end_interaction()
		elif GameState.has_method("set_player_mode") and "PlayerMode" in GameState:
			GameState.set_player_mode(GameState.PlayerMode.PLAYER_ACTIVE)

	await get_tree().create_timer(0.25).timeout
	SceneTransition.transition_out()

	_is_transitioning = false



func _input(event: InputEvent) -> void:
	if not _is_active:
		return

	if _is_transitioning:
		return

	if event.is_action_pressed("IN_INTERACT"):
		get_viewport().set_input_as_handled()
		deactivate_scene()
