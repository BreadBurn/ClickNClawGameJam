extends CanvasLayer

@onready var day_label: Label  = $"PanelContainer/MarginContainer/VBoxContainer/DayLabel"
@onready var gold_label: Label = $"PanelContainer/MarginContainer/VBoxContainer/GoldEarned"

@onready var progress_t1: ProgressBar = $"PanelContainer/MarginContainer/VBoxContainer/ProgressBarT1"
@onready var progress_t2: ProgressBar = $"PanelContainer/MarginContainer/VBoxContainer/ProgressBarT2"
@onready var progress_t3: ProgressBar = $"PanelContainer/MarginContainer/VBoxContainer/ProgressBarT3"
@onready var progress_t4: ProgressBar = $"PanelContainer/MarginContainer/VBoxContainer/ProgressBarT4"

@onready var bars: Array[ProgressBar] = [progress_t1, progress_t2, progress_t3, progress_t4]

var _is_active: bool = false
var _is_transitioning: bool = false

func _ready() -> void:
	hide()
	_is_active = false
	_is_transitioning = false

	if GameState != null and GameState.has_signal("daily_evaluated"):
		GameState.daily_evaluated.connect(_on_daily_evaluated)

	# Use _input instead of _unhandled_input for a UI overlay like this
	set_process_input(true)

func _on_daily_evaluated(coins_earned: int, _types_in_bounds: int, _current_streak: int) -> void:
	_populate_from_state(coins_earned)

	var new_day := GameState.cur_day
	var old_day: int = max(new_day - 1, 0)
	day_label.text = "Day %d -> %d" % [old_day, new_day]

	activate_scene()

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

	# Disable player while recap is active
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

	hide()
	_is_active = false

	# Re-enable player
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
