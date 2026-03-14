extends Node3D

enum FloraType { TYPE_1, TYPE_2, TYPE_3 }
enum AnchorCreationMode { CONVERT_SELF, SPAWN_NEW }

@export var current_type: FloraType = FloraType.TYPE_1

# Spread distances for random spawns
@export var min_spawn_distance: float = 2.0
@export var max_spawn_distance: float = 6.0

# Clustering / anchor creation
@export var cluster_radius: float = 4.0
@export var type2_summon_threshold: int = 5
@export var anchor_creation_mode: AnchorCreationMode = AnchorCreationMode.CONVERT_SELF

# Influence radius for TYPE_1 / TYPE_3 tug-of-war
@export var influence_radius: float = 5.0

# Anchor (TYPE_2) rules
@export var anchor_radius: float = 8.0

# Growth limiting (carrying capacity)
@export var density_check_radius: float = 6.0
@export var max_local_density: int = 5

# Growth chances
@export var type1_growth_base_chance: float = 0.65
@export var type3_growth_base_chance: float = 0.85
@export var type3_extra_density_tolerance: int = 2

@onready var interactable: StaticBody3D = $Interactable

func _ready() -> void:
	GameState.player_slept.connect(_on_player_slept)

	if interactable and interactable.has_signal("interacted"):
		interactable.interacted.connect(_on_interacted)

	_update_meshes()


func _on_interacted() -> void:
	GameState.add_to_inventory(current_type, 1)
	queue_free()


func _on_player_slept(_new_day: int) -> void:
	if is_queued_for_deletion():
		return

	match current_type:
		FloraType.TYPE_1:
			# 1) Majority conversion first
			_apply_majority_conversion()

			# If converted during majority check, stop TYPE_1 behavior this night
			if current_type != FloraType.TYPE_1 or is_queued_for_deletion():
				return

			# 2) Growth
			var nearby_count_1 := _get_nearby_flora_count(FloraType.TYPE_1, density_check_radius)
			var spread_chance_1 := type1_growth_base_chance * (1.0 - (float(nearby_count_1) / max_local_density))

			if spread_chance_1 > 0.0 and randf() <= spread_chance_1:
				_multiply()

			# 3) Anchor creation from strong TYPE_1 clusters
			_summon_anchor_if_clustered()

		FloraType.TYPE_3:
			# TYPE_3 instantly dies if inside anchor radius
			if _is_position_in_anchor(global_position):
				queue_free()
				return

			# 1) Majority conversion first
			_apply_majority_conversion()

			# If converted during majority check, stop TYPE_3 behavior this night
			if current_type != FloraType.TYPE_3 or is_queued_for_deletion():
				return

			# Check again in case a nearby TYPE_1 became an anchor this same cycle
			if _is_position_in_anchor(global_position):
				queue_free()
				return

			# 2) Growth
			var nearby_count_3 := _get_nearby_flora_count(FloraType.TYPE_3, density_check_radius)
			var spread_chance_3 := type3_growth_base_chance * (
				1.0 - (float(nearby_count_3) / float(max_local_density + type3_extra_density_tolerance))
			)

			if spread_chance_3 > 0.0 and randf() <= spread_chance_3:
				_multiply()

		FloraType.TYPE_2:
			# Anchors purge weeds nightly
			_purge_weeds_near_anchor()


# ------------------------------------------------------------
# ECOLOGICAL TUG-OF-WAR
# ------------------------------------------------------------

func _apply_majority_conversion() -> void:
	var count_1 := _count_type_in_radius(FloraType.TYPE_1, global_position, influence_radius)
	var count_3 := _count_type_in_radius(FloraType.TYPE_3, global_position, influence_radius)

	# We do not count self. Ties do nothing.
	match current_type:
		FloraType.TYPE_1:
			# TYPE_1 loses if surrounded by more TYPE_3, unless protected by anchor
			if count_3 > count_1 and not _is_position_in_anchor(global_position):
				current_type = FloraType.TYPE_3
				_update_meshes()

		FloraType.TYPE_3:
			# TYPE_3 converts if surrounded by more TYPE_1
			if count_1 > count_3:
				current_type = FloraType.TYPE_1
				_update_meshes()


# ------------------------------------------------------------
# ANCHOR CREATION
# ------------------------------------------------------------

func _summon_anchor_if_clustered() -> void:
	# Only TYPE_1 may create anchors
	if current_type != FloraType.TYPE_1:
		return

	# Don't create an anchor if one already exists nearby
	if _has_anchor_nearby(anchor_radius):
		return

	# Need enough TYPE_1 nearby to qualify
	var nearby_type1 := _get_nearby_flora_count(FloraType.TYPE_1, cluster_radius)
	if nearby_type1 < type2_summon_threshold:
		return

	# Optional improvement:
	# Only one TYPE_1 in the local cluster is allowed to create the anchor.
	# We choose the "cluster leader" deterministically to avoid multiple anchors spawning at once.
	if not _is_cluster_leader_for_anchor():
		return

	match anchor_creation_mode:
		AnchorCreationMode.CONVERT_SELF:
			current_type = FloraType.TYPE_2
			_update_meshes()

		AnchorCreationMode.SPAWN_NEW:
			var jitter := Vector3(randf_range(-0.6, 0.6), 0.0, randf_range(-0.6, 0.6))
			_spawn_flora_at_position(FloraType.TYPE_2, global_position + jitter)


func _is_cluster_leader_for_anchor() -> bool:
	# Deterministic leader selection:
	# among nearby TYPE_1 plants in cluster_radius, the one with the lowest instance ID becomes leader.
	var my_id := get_instance_id()

	for sibling in get_parent().get_children():
		if sibling == self:
			continue
		if not _is_valid_flora_node(sibling):
			continue
		if sibling.current_type != FloraType.TYPE_1:
			continue

		if global_position.distance_to(sibling.global_position) <= cluster_radius:
			if sibling.get_instance_id() < my_id:
				return false

	return true


# ------------------------------------------------------------
# GROWTH / DUPLICATION
# ------------------------------------------------------------

func _multiply() -> void:
	var type_to_spawn: FloraType = current_type
	_spawn_flora(type_to_spawn)


func _spawn_flora(type: FloraType) -> void:
	var random_angle := randf() * TAU
	var random_distance := randf_range(min_spawn_distance, max_spawn_distance)

	var random_x := cos(random_angle) * random_distance
	var random_z := sin(random_angle) * random_distance

	var spawn_pos := global_position + Vector3(random_x, 0.0, random_z)

	# TYPE_3 cannot spawn inside any anchor radius
	if type == FloraType.TYPE_3 and _is_position_in_anchor(spawn_pos):
		return

	_spawn_flora_at_position(type, spawn_pos)


func _spawn_flora_at_position(type: FloraType, spawn_pos: Vector3) -> void:
	var new_flora := _create_flora_instance()
	if new_flora == null:
		return

	new_flora.current_type = type

	# Avoid modifying tree during iteration
	call_deferred("_deferred_add_flora", new_flora, spawn_pos)


func _create_flora_instance() -> Node3D:
	# This script must be attached to the root of a saved flora scene.
	if scene_file_path.is_empty():
		push_error("scene_file_path is empty. Make sure this script is attached to the root of a saved Flora scene.")
		return null

	var packed := load(scene_file_path) as PackedScene
	if packed == null:
		push_error("Failed to load flora scene from path: " + scene_file_path)
		return null

	var instance := packed.instantiate() as Node3D
	if instance == null:
		push_error("Failed to instantiate flora scene.")
		return null

	return instance


func _deferred_add_flora(new_flora: Node3D, spawn_pos: Vector3) -> void:
	if new_flora == null or not is_instance_valid(new_flora):
		return

	var parent := get_parent()
	if parent == null:
		new_flora.queue_free()
		return

	parent.add_child(new_flora)
	new_flora.global_position = spawn_pos

	if new_flora.has_method("_update_meshes"):
		new_flora.call("_update_meshes")


# ------------------------------------------------------------
# ANCHOR ENFORCEMENT
# ------------------------------------------------------------

func _purge_weeds_near_anchor() -> void:
	for sibling in get_parent().get_children():
		if sibling == self:
			continue
		if not _is_valid_flora_node(sibling):
			continue

		if sibling.current_type == FloraType.TYPE_3:
			if global_position.distance_to(sibling.global_position) <= anchor_radius:
				sibling.queue_free()


func _is_position_in_anchor(target_pos: Vector3) -> bool:
	for sibling in get_parent().get_children():
		if not _is_valid_flora_node(sibling):
			continue

		if sibling.current_type == FloraType.TYPE_2:
			if target_pos.distance_to(sibling.global_position) <= anchor_radius:
				return true

	return false


func _has_anchor_nearby(radius: float) -> bool:
	for sibling in get_parent().get_children():
		if sibling == self:
			continue
		if not _is_valid_flora_node(sibling):
			continue

		if sibling.current_type == FloraType.TYPE_2:
			if global_position.distance_to(sibling.global_position) <= radius:
				return true

	return false


# ------------------------------------------------------------
# UTILITY
# ------------------------------------------------------------

func _get_nearby_flora_count(target_type: FloraType, search_radius: float) -> int:
	var count := 0

	for sibling in get_parent().get_children():
		if sibling == self:
			continue
		if not _is_valid_flora_node(sibling):
			continue

		if sibling.current_type == target_type:
			if global_position.distance_to(sibling.global_position) <= search_radius:
				count += 1

	return count


func _count_type_in_radius(target_type: FloraType, center: Vector3, radius: float) -> int:
	var count := 0

	for sibling in get_parent().get_children():
		if sibling == self:
			continue
		if not _is_valid_flora_node(sibling):
			continue

		if sibling.current_type == target_type:
			if center.distance_to(sibling.global_position) <= radius:
				count += 1

	return count


func _is_valid_flora_node(node: Node) -> bool:
	if node == null:
		return false
	if not is_instance_valid(node):
		return false
	if node.is_queued_for_deletion():
		return false
	return "current_type" in node


func _update_meshes() -> void:
	if has_node("Flora1Mesh"):
		$Flora1Mesh.hide()
	if has_node("Flora2Mesh"):
		$Flora2Mesh.hide()
	if has_node("Flora3Mesh"):
		$Flora3Mesh.hide()

	match current_type:
		FloraType.TYPE_1:
			if has_node("Flora1Mesh"):
				$Flora1Mesh.show()

		FloraType.TYPE_2:
			if has_node("Flora2Mesh"):
				$Flora2Mesh.show()

		FloraType.TYPE_3:
			if has_node("Flora3Mesh"):
				$Flora3Mesh.show()
