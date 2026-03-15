extends Node

signal coins_changed(new_amount: int)
signal inventory_changed()
signal player_slept(new_day: int)
signal player_mode_changed(new_mode: PlayerMode)
signal daily_evaluated(coins_earned: int, types_in_bounds: int, current_streak: int)
signal game_won()

enum PlayerMode {
	PLAYER_ACTIVE,
	PLAYER_INACTIVE
}

var player_mode: PlayerMode = PlayerMode.PLAYER_ACTIVE

var total_coins: int = 0
var cur_day: int = 0

# Inventory tracking
var type_1_count: int = 0
var type_2_count: int = 0
var type_3_count: int = 0
var type_4_count: int = 0

# Ecology win condition tracking
var consecutive_balanced_days: int = 0

# Healthy population band
const MIN_RATIO: float = 0.15
const MAX_RATIO: float = 0.35

# How much each ratio is allowed to drift from the previous balanced day
const CONSISTENCY_TOLERANCE: float = 0.05

# Stores the last balanced day's ratios (used for consistency checks)
var last_stable_ratios: Dictionary = {}
var latest_ratios: Dictionary = {0: 0.0, 1: 0.0, 2: 0.0, 3: 0.0}

# Prevent accidental double-evaluations if sleep is triggered rapidly
var _daily_evaluation_pending: bool = false

# --- References ---
var player: Node3D = null
var player_characterbody: CharacterBody3D = null
var dialogue_box: CanvasLayer = null
var flora_container: Node = null


# ------------------------------------------------------------
# REGISTRATION HELPERS
# ------------------------------------------------------------

func register_player(p: Node3D) -> void:
	player = p
	if p is CharacterBody3D:
		player_characterbody = p as CharacterBody3D
	else:
		player_characterbody = null


func clear_player() -> void:
	player = null
	player_characterbody = null


func has_player() -> bool:
	return player != null


func register_dialogue_box(dialogue: CanvasLayer) -> void:
	dialogue_box = dialogue


func clear_dialogue_box() -> void:
	dialogue_box = null


func has_dialogue_box() -> bool:
	return dialogue_box != null and is_instance_valid(dialogue_box)


func register_flora_container(container: Node) -> void:
	flora_container = container


func clear_flora_container() -> void:
	flora_container = null


func has_flora_container() -> bool:
	return flora_container != null and is_instance_valid(flora_container)


# ------------------------------------------------------------
# DIALOGUE / PLAYER MODE / TELEPORT / ECONOMY
# ------------------------------------------------------------

func start_dialogue(npc_name: String, lines: PackedStringArray) -> void:
	if not has_dialogue_box() or lines.is_empty() or is_player_inactive():
		return
	dialogue_box.start_dialogue(npc_name, lines)


func end_current_dialogue() -> void:
	if has_dialogue_box() and dialogue_box.has_method("end_dialogue"):
		dialogue_box.end_dialogue()


func is_dialogue_active() -> bool:
	if has_dialogue_box() and "is_dialogue_active" in dialogue_box:
		return dialogue_box.is_dialogue_active
	return false


func set_player_mode(new_mode: PlayerMode) -> void:
	if player_mode == new_mode:
		return
	player_mode = new_mode
	if player_mode == PlayerMode.PLAYER_INACTIVE and player_characterbody != null:
		player_characterbody.velocity = Vector3.ZERO
	player_mode_changed.emit(player_mode)


func is_player_active() -> bool:
	return player_mode == PlayerMode.PLAYER_ACTIVE


func is_player_inactive() -> bool:
	return player_mode == PlayerMode.PLAYER_INACTIVE


func begin_interaction() -> void:
	set_player_mode(PlayerMode.PLAYER_INACTIVE)


func end_interaction() -> void:
	set_player_mode(PlayerMode.PLAYER_ACTIVE)


func teleport_player_to_node(target: Node3D) -> void:
	if player == null or target == null:
		return
	if player_characterbody:
		player_characterbody.velocity = Vector3.ZERO
	player.global_transform = target.global_transform


func teleport_player_to_position(pos: Vector3, y_degrees: float = NAN) -> void:
	if player == null:
		return
	if player_characterbody:
		player_characterbody.velocity = Vector3.ZERO
	player.global_position = pos
	if not is_nan(y_degrees):
		var basis := Basis(Vector3.UP, deg_to_rad(y_degrees))
		player.global_transform.basis = basis


func add_coins(amount: int) -> void:
	if amount == 0:
		return
	total_coins += amount
	coins_changed.emit(total_coins)


func add_to_inventory(type: int, amount: int = 1) -> void:
	print("added plant of type: ", type)
	match type:
		0: type_1_count += amount
		1: type_2_count += amount
		2: type_3_count += amount
		3: type_4_count += amount
	inventory_changed.emit()


# ------------------------------------------------------------
# TIME AND EVALUATION
# ------------------------------------------------------------

func go_to_sleep() -> void:
	if _daily_evaluation_pending:
		return

	_daily_evaluation_pending = true
	cur_day += 1
	print("Day updated: ", cur_day)

	# Let all flora react to the new day first
	player_slept.emit(cur_day)

	# Evaluate after flora has acted and deferred spawns have had time to appear
	call_deferred("_evaluate_daily_ecosystem_deferred")


func _evaluate_daily_ecosystem_deferred() -> void:
	await get_tree().process_frame
	_evaluate_daily_ecosystem()
	_daily_evaluation_pending = false


func _evaluate_daily_ecosystem() -> void:
	if not has_flora_container():
		push_warning("FloraContainer is not registered in GameState!")
		consecutive_balanced_days = 0
		last_stable_ratios.clear()
		daily_evaluated.emit(0, 0, 0)
		return

	var counts := get_flora_counts()
	var total_flora := _sum_counts(counts)

	if total_flora == 0:
		latest_ratios = {0: 0.0, 1: 0.0, 2: 0.0, 3: 0.0}
		consecutive_balanced_days = 0
		last_stable_ratios.clear()
		daily_evaluated.emit(0, 0, 0)
		return

	latest_ratios = _counts_to_ratios(counts, total_flora)

	var types_in_bounds := 0
	for type in latest_ratios.keys():
		var ratio: float = latest_ratios[type]
		if ratio >= MIN_RATIO and ratio <= MAX_RATIO:
			types_in_bounds += 1

	var all_types_balanced := (types_in_bounds == 4)

	# Reward healthy ecosystems
	var coins_earned := types_in_bounds * 25
	if all_types_balanced:
		coins_earned += 50

	if all_types_balanced:
		if consecutive_balanced_days == 0 or last_stable_ratios.is_empty():
			# First balanced day in a possible streak becomes the baseline
			consecutive_balanced_days = 1
			last_stable_ratios = latest_ratios.duplicate(true)
			print("Balanced ecosystem established. Streak: ", consecutive_balanced_days)
		else:
			if _ratios_are_consistent(latest_ratios, last_stable_ratios):
				consecutive_balanced_days += 1
				last_stable_ratios = latest_ratios.duplicate(true)
				print("Stable equilibrium maintained. Streak: ", consecutive_balanced_days)
			else:
				# Still balanced, but ratios drifted too much — start a new streak from today
				consecutive_balanced_days = 1
				last_stable_ratios = latest_ratios.duplicate(true)
				print("Balanced, but ratios shifted too much. New streak started.")
	else:
		consecutive_balanced_days = 0
		last_stable_ratios.clear()
		print("Equilibrium broken. Streak reset.")

	add_coins(coins_earned)
	daily_evaluated.emit(coins_earned, types_in_bounds, consecutive_balanced_days)

	if consecutive_balanced_days >= 3:
		print("YOU WIN! 3-Day Equilibrium Achieved!")
		game_won.emit()


# ------------------------------------------------------------
# ECOLOGY HELPERS (USED BY FLORA)
# ------------------------------------------------------------

func get_flora_counts() -> Dictionary:
	var counts := {0: 0, 1: 0, 2: 0, 3: 0}

	if not has_flora_container():
		return counts

	for child in flora_container.get_children():
		if child == null or not is_instance_valid(child) or child.is_queued_for_deletion():
			continue
		if "current_type" in child:
			counts[int(child.current_type)] += 1

	return counts


func get_flora_ratios() -> Dictionary:
	var counts := get_flora_counts()
	var total := _sum_counts(counts)
	return _counts_to_ratios(counts, total)


func get_flora_ratio(type: int) -> float:
	var ratios := get_flora_ratios()
	return float(ratios.get(type, 0.0))


func is_type_underrepresented(type: int) -> bool:
	return get_flora_ratio(type) < MIN_RATIO


func is_type_overrepresented(type: int) -> bool:
	return get_flora_ratio(type) > MAX_RATIO


func can_type_gain_population(type: int) -> bool:
	return get_flora_ratio(type) < MAX_RATIO


func can_type_lose_population(type: int) -> bool:
	return get_flora_ratio(type) > MIN_RATIO


func can_convert_population(from_type: int, to_type: int) -> bool:
	var counts := get_flora_counts()
	var total := _sum_counts(counts)

	if total <= 0:
		return false
	if counts.get(from_type, 0) <= 0:
		return false

	var from_ratio := float(counts[from_type]) / float(total)
	var to_ratio := float(counts[to_type]) / float(total)

	# Don't drain a type that's already too low,
	# and don't feed a type that's already too high.
	if from_ratio <= MIN_RATIO:
		return false
	if to_ratio >= MAX_RATIO:
		return false

	return true


func get_ecology_action_multiplier(type: int) -> float:
	var ratio := get_flora_ratio(type)
	var midpoint := (MIN_RATIO + MAX_RATIO) * 0.5

	if ratio < MIN_RATIO:
		return 1.35
	if ratio > MAX_RATIO:
		return 0.25
	if ratio < midpoint:
		return 1.10

	return 1.0


# ------------------------------------------------------------
# INTERNAL HELPERS
# ------------------------------------------------------------

func _sum_counts(counts: Dictionary) -> int:
	return int(counts.get(0, 0)) + int(counts.get(1, 0)) + int(counts.get(2, 0)) + int(counts.get(3, 0))


func _counts_to_ratios(counts: Dictionary, total_flora: int) -> Dictionary:
	var ratios := {0: 0.0, 1: 0.0, 2: 0.0, 3: 0.0}

	if total_flora <= 0:
		return ratios

	for type in ratios.keys():
		ratios[type] = float(counts[type]) / float(total_flora)

	return ratios


func _ratios_are_consistent(current_ratios: Dictionary, previous_ratios: Dictionary) -> bool:
	if previous_ratios.is_empty():
		return true

	for type in current_ratios.keys():
		var current_value := float(current_ratios.get(type, 0.0))
		var previous_value := float(previous_ratios.get(type, 0.0))

		if abs(current_value - previous_value) > CONSISTENCY_TOLERANCE:
			return false

	return true
