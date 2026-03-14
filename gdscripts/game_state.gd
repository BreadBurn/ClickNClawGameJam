extends Node

signal coins_changed(new_amount: int)
signal player_slept(new_day: int)

var total_coins: int = 0
var cur_day: int = 0

func add_coins(amount: int) -> void:
	total_coins += amount
	print("Coins updated! Total: ", total_coins)
	coins_changed.emit(total_coins)

func go_to_sleep() -> void:
	#goo goo gaa gaa time for uuuuu
	cur_day += 1
	print("Day updated: ", cur_day)
	player_slept.emit(cur_day)
