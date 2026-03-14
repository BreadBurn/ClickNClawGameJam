extends CanvasLayer

@onready var panel: Panel = $Panel
@onready var name_label: Label = $Panel/NameLabel
@onready var dialogue_label: RichTextLabel = $Panel/DialogueLabel
@onready var continue_label: Label = $Panel/ContinueLabel

var dialogue_lines: PackedStringArray = []
var current_line_index: int = 0
var speaker_name: String = ""
var is_dialogue_active: bool = false
var can_advance: bool = false
var is_closing: bool = false

const INTERACT_ACTION := "IN_INTERACT"
const START_DELAY := 0.15
const ADVANCE_DELAY := 0.10
const CLOSE_COOLDOWN := 0.10


func _ready() -> void:
	GameState.register_dialogue_box(self)
	hide_dialogue()


func _exit_tree() -> void:
	if GameState.dialogue_box == self:
		GameState.clear_dialogue_box()


func _unhandled_input(event: InputEvent) -> void:
	if not is_dialogue_active:
		return

	if is_closing:
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed(INTERACT_ACTION) and can_advance:
		get_viewport().set_input_as_handled()
		advance_dialogue()


func start_dialogue(npc_name: String, lines: PackedStringArray) -> void:
	if lines.is_empty():
		return

	# Prevent overlapping dialogue starts
	if is_dialogue_active or is_closing:
		return

	speaker_name = npc_name
	dialogue_lines = lines
	current_line_index = 0
	is_dialogue_active = true
	is_closing = false
	can_advance = false

	name_label.text = speaker_name
	dialogue_label.clear()
	dialogue_label.append_text(dialogue_lines[current_line_index])
	continue_label.text = "Continue(RMS)"

	panel.show()
	show()

	GameState.begin_interaction()

	await get_tree().create_timer(START_DELAY).timeout

	# Only re-enable advance if still active
	if is_dialogue_active and not is_closing:
		can_advance = true


func advance_dialogue() -> void:
	if not is_dialogue_active or is_closing:
		return

	can_advance = false
	current_line_index += 1

	if current_line_index >= dialogue_lines.size():
		_close_dialogue_safely()
		return

	dialogue_label.clear()
	dialogue_label.append_text(dialogue_lines[current_line_index])

	await get_tree().create_timer(ADVANCE_DELAY).timeout

	if is_dialogue_active and not is_closing:
		can_advance = true


func _close_dialogue_safely() -> void:
	if is_closing:
		return

	is_closing = true
	is_dialogue_active = false
	can_advance = false

	# Hide the UI immediately so it feels responsive
	hide_dialogue()

	# Wait one frame so this input event fully finishes processing
	await get_tree().process_frame

	# IMPORTANT: do not give control back until interact is released
	while Input.is_action_pressed(INTERACT_ACTION):
		await get_tree().process_frame

	# Tiny extra cooldown to avoid edge-case re-triggering
	await get_tree().create_timer(CLOSE_COOLDOWN).timeout

	# Clear dialogue data
	dialogue_lines = []
	current_line_index = 0
	speaker_name = ""

	is_closing = false

	# Now safely return control to the player
	GameState.end_interaction()


func end_dialogue() -> void:
	# External/manual force-close support
	if not is_dialogue_active and not is_closing:
		return

	_close_dialogue_safely()


func hide_dialogue() -> void:
	panel.hide()
	hide()
