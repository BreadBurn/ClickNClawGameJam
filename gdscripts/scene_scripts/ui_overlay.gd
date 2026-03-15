extends CanvasLayer

# --- UI Node References ---
# Using Scene Unique Nodes (%) is the safest way to grab UI elements 
# so the script doesn't break if you move nodes around in your layout.
@onready var stamina_bar: ProgressBar = %StaminaBar
@onready var coins_label: Label = %CoinsLabel
@onready var day_label: Label = %DayLabel
@onready var streak_label: Label = %StreakLabel
@onready var inventory_label: Label = %InventoryLabel

func _ready() -> void:
	# 1. Connect to GameState signals
	GameState.coins_changed.connect(_on_coins_changed)
	GameState.inventory_changed.connect(_on_inventory_changed)
	GameState.player_slept.connect(_on_player_slept)
	GameState.stamina_changed.connect(_on_stamina_changed)
	GameState.daily_evaluated.connect(_on_daily_evaluated)
	GameState.game_won.connect(_on_game_won)
	
	# 2. Initialize the UI with starting values
	_on_coins_changed(GameState.total_coins)
	_on_inventory_changed()
	_on_player_slept(GameState.cur_day)
	_on_stamina_changed(GameState.current_stamina, GameState.max_stamina)
	_update_streak_display(GameState.consecutive_balanced_days)


# --- Signal Callbacks ---

func _on_coins_changed(new_amount: int) -> void:
	if coins_label:
		coins_label.text = "Coins: %d" % new_amount

func _on_inventory_changed() -> void:
	if inventory_label:
		# Formats the string to show all 4 plant types cleanly
		inventory_label.text = "[Key 1] %d | [Key 2] %d | [Key 3] %d | [Key 4] %d" % [
			GameState.type_1_count,
			GameState.type_2_count,
			GameState.type_3_count,
			GameState.type_4_count
		]

func _on_player_slept(new_day: int) -> void:
	if day_label:
		day_label.text = "Day: %d" % new_day

func _on_stamina_changed(current_stamina: int, max_stamina: int) -> void:
	if stamina_bar:
		stamina_bar.max_value = max_stamina
		stamina_bar.value = current_stamina

func _on_daily_evaluated(_coins_earned: int, _types_in_bounds: int, current_streak: int) -> void:
	# We only care about updating the streak visual here
	_update_streak_display(current_streak)

func _update_streak_display(streak: int) -> void:
	if streak_label:
		streak_label.text = "Eco Streak: %d/3" % streak

func _on_game_won() -> void:
	if streak_label:
		streak_label.text = "ECOLOGY BALANCED! YOU WIN!"
		# Optional: Make the text gold when they win!
		streak_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
