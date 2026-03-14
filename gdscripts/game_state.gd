
extends Node

signal coins_changed(new_amount: int)
signal inventory_changed()
signal player_slept(new_day: int)
signal player_mode_changed(new_mode: PlayerMode)

enum PlayerMode {
	PLAYER_ACTIVE,
	PLAYER_INACTIVE
}

var player_mode: PlayerMode = PlayerMode.PLAYER_ACTIVE

var total_coins: int = 0
var cur_day: int = 0

# Inventory tracking
var type_1_count: int = 0 # Nurtured Flora (Moss)
var type_2_count: int = 0 # Anchor (Orchids)
var type_3_count: int = 0 # Invasive Weed

# --- Player reference / scene & teleport helpers ---
var player: Node3D = null
var player_characterbody: CharacterBody3D = null

# --- Dialogue reference ---
var dialogue_box: CanvasLayer = null

func register_player(p: Node3D) -> void:
	player = p
	
	# Optional: cache a CharacterBody3D if your player is one, to easily zero velocity
	if p is CharacterBody3D:
		player_characterbody = p as CharacterBody3D
	else:
		player_characterbody = null


func clear_player() -> void:
	player = null
	player_characterbody = null


func has_player() -> bool:
	return player != null


# ------------------------------------------------------------
# DIALOGUE REGISTRATION / HELPERS
# ------------------------------------------------------------

func register_dialogue_box(dialogue: CanvasLayer) -> void:
	dialogue_box = dialogue


func clear_dialogue_box() -> void:
	dialogue_box = null


func has_dialogue_box() -> bool:
	return dialogue_box != null and is_instance_valid(dialogue_box)


func start_dialogue(npc_name: String, lines: PackedStringArray) -> void:
	if not has_dialogue_box():
		push_warning("Cannot start dialogue: dialogue_box is not registered in GameState.")
		return

	if lines.is_empty():
		push_warning("Cannot start dialogue: no dialogue lines were provided.")
		return

	if is_player_inactive():
		return

	dialogue_box.start_dialogue(npc_name, lines)


func end_current_dialogue() -> void:
	if not has_dialogue_box():
		return

	if dialogue_box.has_method("end_dialogue"):
		dialogue_box.end_dialogue()


func is_dialogue_active() -> bool:
	if not has_dialogue_box():
		return false

	if "is_dialogue_active" in dialogue_box:
		return dialogue_box.is_dialogue_active

	return false


# ------------------------------------------------------------
# PLAYER MODE / INTERACTION STATE
# ------------------------------------------------------------

func set_player_mode(new_mode: PlayerMode) -> void:
	if player_mode == new_mode:
		return

	player_mode = new_mode

	# If disabling player control, stop movement immediately
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


# ------------------------------------------------------------
# TELEPORT HELPERS
# ------------------------------------------------------------

func teleport_player_to_node(target: Node3D) -> void:
	if player == null or target == null:
		push_warning("Teleport failed: player or target is null")
		return

	# To avoid physics oddities, zero out movement if CharacterBody3D
	if player_characterbody:
		player_characterbody.velocity = Vector3.ZERO

	# Do transform-level teleport so rotation is preserved if needed
	player.global_transform = target.global_transform


# Overload: teleport using a position and optional y-rotation
func teleport_player_to_position(pos: Vector3, y_degrees: float = NAN) -> void:
	if player == null:
		push_warning("Teleport failed: player not set")
		return

	if player_characterbody:
		player_characterbody.velocity = Vector3.ZERO

	player.global_position = pos

	if not is_nan(y_degrees):
		var basis := Basis(Vector3.UP, deg_to_rad(y_degrees))
		player.global_transform.basis = basis


# ------------------------------------------------------------
# ECONOMY / INVENTORY
# ------------------------------------------------------------

func add_coins(amount: int) -> void:
	total_coins += amount
	print("Coins updated! Total: ", total_coins)
	coins_changed.emit(total_coins)


func add_to_inventory(type: int, amount: int = 1) -> void:
	match type:
		0:
			type_1_count += amount
			print("Type 1 collected! Total: ", type_1_count)
		1:
			type_2_count += amount
			print("Type 2 collected! Total: ", type_2_count)
		2:
			type_3_count += amount
			print("Weed collected! Total: ", type_3_count)

	inventory_changed.emit()


# ------------------------------------------------------------
# TIME
# ------------------------------------------------------------

func go_to_sleep() -> void:
	cur_day += 1
	print("Day updated: ", cur_day)
	player_slept.emit(cur_day)
