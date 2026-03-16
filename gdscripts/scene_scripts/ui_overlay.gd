extends CanvasLayer

# --- UI Node References ---
@onready var stamina_bar: ProgressBar = %StaminaBar
@onready var coins_label: Label = %CoinsLabel
@onready var day_label: Label = %DayLabel
@onready var streak_label: Label = %StreakLabel
@onready var inventory_label: Label = %InventoryLabel

@onready var plant1_rect: ColorRect = %Plant1Rect
@onready var plant2_rect: ColorRect = %Plant2Rect
@onready var plant3_rect: ColorRect = %Plant3Rect
@onready var plant4_rect: ColorRect = %Plant4Rect
@onready var _plant_rects: Array[ColorRect] = [plant1_rect, plant2_rect, plant3_rect, plant4_rect]

# --- Slot colors ---
const UNSELECTED_COLOR := Color(0.25, 0.25, 0.25, 0.5) # darker gray
const SELECTED_COLOR   := Color(0.85, 0.85, 0.85, 0.5) # lighter gray

func _ready() -> void:
	# 1. Connect to GameState signals
	GameState.coins_changed.connect(_on_coins_changed)
	GameState.inventory_changed.connect(_on_inventory_changed)
	GameState.player_slept.connect(_on_player_slept)
	GameState.stamina_changed.connect(_on_stamina_changed)
	GameState.daily_evaluated.connect(_on_daily_evaluated)
	GameState.game_won.connect(_on_game_won)
	GameState.held_plant_changed.connect(_on_held_plant_changed)

	# 2. Initialize the UI with starting values
	_on_coins_changed(GameState.total_coins)
	_on_inventory_changed()
	_on_player_slept(GameState.cur_day)
	_on_stamina_changed(GameState.current_stamina, GameState.max_stamina)
	_update_streak_display(GameState.consecutive_balanced_days)
	_on_held_plant_changed(GameState.held_plant_state)


# --- Signal Callbacks ---

func _on_coins_changed(new_amount: int) -> void:
	if coins_label:
		coins_label.text = "Coins: %d" % new_amount

func _on_inventory_changed() -> void:
	if inventory_label:
		inventory_label.text = "[Key 1] %d  |  [Key 2] %d  |  [Key 3] %d  |  [Key 4] %d" % [
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
	_update_streak_display(current_streak)

func _update_streak_display(streak: int) -> void:
	if streak_label:
		streak_label.text = "Eco Streak: %d/3" % streak

func _on_game_won() -> void:
	if streak_label:
		streak_label.text = "ECOLOGY BALANCED! YOU WIN!"
		streak_label.add_theme_color_override("font_color", Color(1, 0.84, 0))

func _on_held_plant_changed(new_state: GameState.HeldPlantState) -> void:
	_update_held_plant_rects(new_state)


func _update_held_plant_rects(held_state: GameState.HeldPlantState) -> void:
	# First, set all slots to dark/unselected
	for rect in _plant_rects:
		if rect == null:
			continue
		rect.color = UNSELECTED_COLOR

	# Then brighten the selected slot
	match held_state:
		GameState.HeldPlantState.IN_PLANT1:
			plant1_rect.color = SELECTED_COLOR
		GameState.HeldPlantState.IN_PLANT2:
			plant2_rect.color = SELECTED_COLOR
		GameState.HeldPlantState.IN_PLANT3:
			plant3_rect.color = SELECTED_COLOR
		GameState.HeldPlantState.IN_PLANT4:
			plant4_rect.color = SELECTED_COLOR
		GameState.HeldPlantState.IN_NONE:
			pass
