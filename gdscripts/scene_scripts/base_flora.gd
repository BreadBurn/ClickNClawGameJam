extends Node3D

enum FloraType { TYPE_1, TYPE_2, TYPE_3, TYPE_4 }

@export var current_type: FloraType = FloraType.TYPE_1

# Spawn & Conversion distances
@export var min_spawn_distance: float = 2.0
@export var max_spawn_distance: float = 6.0
@export var conversion_radius: float = 4.0

# True empty-space spawning
@export var spawn_clearance_radius: float = 1.25
@export var spawn_attempts: int = 6

# --- Playable Area Boundaries ---
@export var x_start: float = -20.0
@export var x_end: float = 20.0
@export var z_start: float = -20.0
@export var z_end: float = 20.0
# -------------------------------

# Growth limiting for TYPE_1 (Pioneer)
@export var density_check_radius: float = 6.0
@export var max_local_density: int = 5
@export var type1_growth_base_chance: float = 0.8

# Conversion chances
@export var type2_conversion_chance: float = 0.6
@export var type3_conversion_chance: float = 0.7
@export var type4_conversion_chance: float = 0.5

# Bastion (TYPE_2) fusion threshold
@export var bastion_fuse_threshold: int = 2 # Needs 2 neighbors (3 total) to fuse

# Fused TYPE_2 / Bastion Core bonuses
@export var fused_type2_resist_chance: float = 0.75
@export var fused_type2_purify_chance: float = 0.45
@export var fused_type2_purify_radius: float = 5.0
@export var fused_type2_conversion_bonus: float = 0.2
@export var fused_type2_bonus_harvest: int = 1

# Cleanser (TYPE_4) lifespan
@export var type4_max_lifespan: int = 3
var current_lifespan: int = 0

var last_day_acted: int = -1

@onready var interactable: Node = get_node_or_null("Interactable")


func _ready() -> void:
	GameState.player_slept.connect(_on_player_slept)

	if interactable and interactable.has_signal("interacted"):
		interactable.interacted.connect(_on_interacted)

	if current_type == FloraType.TYPE_4:
		current_lifespan = type4_max_lifespan
	else:
		current_lifespan = 0

	add_to_group("flora")
	_update_meshes()


func _on_interacted() -> void:
	var amount := 1

	# Fused Bastions are more rewarding to harvest
	if _is_fused_type2():
		amount += fused_type2_bonus_harvest

	GameState.add_to_inventory(int(current_type), amount)

	# Removing this node may change nearby TYPE_2 fusion states
	_refresh_nearby_type2_visuals()
	queue_free()


func _on_player_slept(new_day: int) -> void:
	if is_queued_for_deletion() or last_day_acted == new_day:
		return

	last_day_acted = new_day

	match current_type:
		FloraType.TYPE_1:
			_handle_type1_growth()

		FloraType.TYPE_2:
			_handle_type2_behavior()

		FloraType.TYPE_3:
			_handle_type3_behavior()

		FloraType.TYPE_4:
			_handle_type4_behavior()

	_update_meshes()


# ------------------------------------------------------------
# PER-TYPE DAILY LOGIC
# ------------------------------------------------------------

func _handle_type1_growth() -> void:
	if not _can_gain_population(FloraType.TYPE_1):
		return

	var nearby_count_1 := _get_nearby_flora_count(FloraType.TYPE_1, density_check_radius)
	var spread_chance := type1_growth_base_chance * (1.0 - (float(nearby_count_1) / float(max_local_density)))
	spread_chance = clamp(spread_chance, 0.0, 1.0)
	spread_chance = _get_ecology_adjusted_chance(spread_chance, FloraType.TYPE_1)

	if spread_chance > 0.0 and randf() <= spread_chance:
		_spawn_flora_in_empty_space(FloraType.TYPE_1)


func _handle_type2_behavior() -> void:
	if _can_convert_population(FloraType.TYPE_1, FloraType.TYPE_2):
		var conversion_chance := _get_ecology_adjusted_chance(type2_conversion_chance, FloraType.TYPE_2)

		# Fused Bastions are slightly better at consolidating TYPE_1
		if _is_fused_type2():
			conversion_chance = min(conversion_chance + fused_type2_conversion_bonus, 1.0)

		if randf() <= conversion_chance:
			_convert_nearby_target(FloraType.TYPE_1, FloraType.TYPE_2)

	# Fused Bastions can push back TYPE_3, helping maintain equilibrium
	if _is_fused_type2() and _can_convert_population(FloraType.TYPE_3, FloraType.TYPE_2):
		var purify_chance := _get_ecology_adjusted_chance(fused_type2_purify_chance, FloraType.TYPE_2)
		if randf() <= purify_chance:
			_convert_nearby_target(FloraType.TYPE_3, FloraType.TYPE_2, fused_type2_purify_radius)


func _handle_type3_behavior() -> void:
	if not _can_convert_population(FloraType.TYPE_2, FloraType.TYPE_3):
		return

	var conversion_chance := _get_ecology_adjusted_chance(type3_conversion_chance, FloraType.TYPE_3)
	if randf() <= conversion_chance:
		_convert_nearby_target(FloraType.TYPE_2, FloraType.TYPE_3)


func _handle_type4_behavior() -> void:
	current_lifespan -= 1

	if current_lifespan <= 0:
		_refresh_nearby_type2_visuals()
		queue_free()
		return

	if not _can_convert_population(FloraType.TYPE_3, FloraType.TYPE_4):
		return

	var conversion_chance := _get_ecology_adjusted_chance(type4_conversion_chance, FloraType.TYPE_4)
	if randf() <= conversion_chance:
		_convert_nearby_target(FloraType.TYPE_3, FloraType.TYPE_4)


# ------------------------------------------------------------
# TARGETED CONVERSION LOGIC
# ------------------------------------------------------------

func _convert_nearby_target(target_type: FloraType, new_type: FloraType, search_radius: float = -1.0) -> void:
	if search_radius < 0.0:
		search_radius = conversion_radius

	var potential_targets := _get_nearby_flora_of_type(target_type, search_radius)
	if potential_targets.is_empty():
		return

	var target_node = potential_targets.pick_random()

	# Fused TYPE_2 can resist TYPE_3 conversion
	if target_type == FloraType.TYPE_2 and new_type == FloraType.TYPE_3:
		if target_node.has_method("_can_resist_type3_conversion") and target_node.call("_can_resist_type3_conversion"):
			if target_node.has_method("_on_bastion_resisted"):
				target_node.call("_on_bastion_resisted")
			return

	target_node.current_type = new_type
	target_node.last_day_acted = last_day_acted

	if new_type == FloraType.TYPE_4:
		target_node.current_lifespan = target_node.type4_max_lifespan
	else:
		target_node.current_lifespan = 0

	target_node._update_meshes()
	target_node._refresh_nearby_type2_visuals()
	_refresh_nearby_type2_visuals()


# ------------------------------------------------------------
# GROWTH / DUPLICATION (For TYPE_1)
# ------------------------------------------------------------

func _spawn_flora_in_empty_space(type: FloraType) -> void:
	var found_position := false
	var spawn_pos := Vector3.ZERO

	for _i in range(spawn_attempts):
		var random_angle := randf() * TAU
		var random_distance := randf_range(min_spawn_distance, max_spawn_distance)

		var random_x := cos(random_angle) * random_distance
		var random_z := sin(random_angle) * random_distance

		var candidate := global_position + Vector3(random_x, 0.0, random_z)

		# Enforce map boundaries
		candidate.x = clamp(candidate.x, x_start, x_end)
		candidate.z = clamp(candidate.z, z_start, z_end)

		if _is_spawn_position_clear(candidate):
			spawn_pos = candidate
			found_position = true
			break

	if not found_position:
		return

	var new_flora := _create_flora_instance()
	if new_flora == null:
		return

	new_flora.current_type = type
	new_flora.last_day_acted = last_day_acted
	call_deferred("_deferred_add_flora", new_flora, spawn_pos)


func _is_spawn_position_clear(world_pos: Vector3) -> bool:
	var parent := get_parent()
	if parent == null:
		return false

	for sibling in parent.get_children():
		if not _is_valid_flora_node(sibling):
			continue

		if world_pos.distance_to(sibling.global_position) < spawn_clearance_radius:
			return false

	return true


func _create_flora_instance() -> Node3D:
	if scene_file_path.is_empty():
		return null

	var packed := load(scene_file_path) as PackedScene
	if packed == null:
		return null

	return packed.instantiate() as Node3D


func _deferred_add_flora(new_flora: Node3D, spawn_pos: Vector3) -> void:
	if new_flora == null or not is_instance_valid(new_flora):
		return

	var parent := get_parent()
	if parent == null:
		new_flora.queue_free()
		return

	parent.add_child(new_flora)
	new_flora.global_position = spawn_pos

	if "current_type" in new_flora:
		if new_flora.current_type == FloraType.TYPE_4:
			new_flora.current_lifespan = new_flora.type4_max_lifespan
		else:
			new_flora.current_lifespan = 0

	if new_flora.has_method("_update_meshes"):
		new_flora.call("_update_meshes")

	if new_flora.has_method("_refresh_nearby_type2_visuals"):
		new_flora.call("_refresh_nearby_type2_visuals")


# ------------------------------------------------------------
# ECOLOGY HELPERS
# ------------------------------------------------------------

func _can_gain_population(type: FloraType) -> bool:
	if GameState != null and GameState.has_method("can_type_gain_population"):
		return GameState.can_type_gain_population(int(type))
	return true


func _can_convert_population(from_type: FloraType, to_type: FloraType) -> bool:
	if GameState != null and GameState.has_method("can_convert_population"):
		return GameState.can_convert_population(int(from_type), int(to_type))
	return true


func _get_ecology_adjusted_chance(base_chance: float, acting_type: FloraType) -> float:
	base_chance = clamp(base_chance, 0.0, 1.0)

	if GameState == null or not GameState.has_method("get_ecology_action_multiplier"):
		return base_chance

	var multiplier: float = GameState.get_ecology_action_multiplier(int(acting_type))
	return clamp(base_chance * multiplier, 0.0, 1.0)


# ------------------------------------------------------------
# FUSED TYPE_2 / BASTION CORE HELPERS
# ------------------------------------------------------------

func _is_fused_type2() -> bool:
	if current_type != FloraType.TYPE_2:
		return false

	return _get_nearby_flora_count(FloraType.TYPE_2, density_check_radius) >= bastion_fuse_threshold


func _can_resist_type3_conversion() -> bool:
	return _is_fused_type2() and randf() <= fused_type2_resist_chance


func _on_bastion_resisted() -> void:
	# Hook for future VFX/SFX
	_update_meshes()


func _refresh_nearby_type2_visuals() -> void:
	var parent := get_parent()
	if parent == null:
		return

	if current_type == FloraType.TYPE_2:
		_update_meshes()

	for sibling in parent.get_children():
		if sibling == self:
			continue
		if not _is_valid_flora_node(sibling):
			continue
		if sibling.current_type != FloraType.TYPE_2:
			continue

		if global_position.distance_to(sibling.global_position) <= density_check_radius:
			if sibling.has_method("_update_meshes"):
				sibling.call("_update_meshes")


# ------------------------------------------------------------
# UTILITY
# ------------------------------------------------------------

func _get_nearby_flora_count(target_type: FloraType, search_radius: float) -> int:
	return _get_nearby_flora_of_type(target_type, search_radius).size()


func _get_nearby_flora_of_type(target_type: FloraType, search_radius: float) -> Array:
	var matches: Array = []

	var parent := get_parent()
	if parent == null:
		return matches

	for sibling in parent.get_children():
		if sibling == self:
			continue
		if not _is_valid_flora_node(sibling):
			continue

		if sibling.current_type == target_type:
			if global_position.distance_to(sibling.global_position) <= search_radius:
				matches.append(sibling)

	return matches


func _is_valid_flora_node(node: Node) -> bool:
	if node == null or not is_instance_valid(node) or node.is_queued_for_deletion():
		return false

	return "current_type" in node


# ------------------------------------------------------------
# VISUAL UPDATES
# ------------------------------------------------------------

func _update_meshes() -> void:
	if has_node("Flora1Mesh"):
		$Flora1Mesh.hide()
	if has_node("Flora2SingleMesh"):
		$Flora2SingleMesh.hide()
	if has_node("Flora2FusedMesh"):
		$Flora2FusedMesh.hide()
	if has_node("Flora3Mesh"):
		$Flora3Mesh.hide()
	if has_node("Flora4Mesh"):
		$Flora4Mesh.hide()

	match current_type:
		FloraType.TYPE_1:
			if has_node("Flora1Mesh"):
				$Flora1Mesh.show()

		FloraType.TYPE_2:
			var nearby_type2 := _get_nearby_flora_count(FloraType.TYPE_2, density_check_radius)
			if nearby_type2 >= bastion_fuse_threshold:
				if has_node("Flora2FusedMesh"):
					$Flora2FusedMesh.show()
			else:
				if has_node("Flora2SingleMesh"):
					$Flora2SingleMesh.show()

		FloraType.TYPE_3:
			if has_node("Flora3Mesh"):
				$Flora3Mesh.show()

		FloraType.TYPE_4:
			if has_node("Flora4Mesh"):
				$Flora4Mesh.show()
