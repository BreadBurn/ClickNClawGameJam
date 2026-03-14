extends Node3D

@export var npc_name: String = "Villager"
@export_multiline var dialogue_text: String = "Hello there!\nNice to see you.\nCome back soon."

func _on_interactable_interacted() -> void:
	var lines := dialogue_text.split("\n")
	GameState.start_dialogue(npc_name, lines)
