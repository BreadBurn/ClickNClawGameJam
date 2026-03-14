extends Node

signal coins_changed(new_amount: int)
signal inventory_changed() # New signal to update UI later
signal player_slept(new_day: int)

var total_coins: int = 0
var cur_day: int = 0

# Inventory tracking
var type_1_count: int = 0 # Nurtured Flora (Moss)
var type_2_count: int = 0 # Anchor (Orchids)
var type_3_count: int = 0 # Invasive Weed

func add_coins(amount: int) -> void:
	total_coins += amount
	print("Coins updated! Total: ", total_coins)
	coins_changed.emit(total_coins)

# New function to handle picking up plants
func add_to_inventory(type: int, amount: int = 1) -> void:
	match type:
		0: # FloraType.TYPE_1
			type_1_count += amount
			print("Type 1 collected! Total: ", type_1_count)
		1: # FloraType.TYPE_2
			type_2_count += amount
			print("Type 2 collected! Total: ", type_2_count)
		2: # FloraType.TYPE_3
			type_3_count += amount
			print("Weed collected! Total: ", type_3_count)
			
	inventory_changed.emit()

func go_to_sleep() -> void:
	cur_day += 1
	print("Day updated: ", cur_day)
	player_slept.emit(cur_day)
