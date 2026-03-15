extends VBoxContainer

# Set these in the Inspector for each specific item you put in the shop
@export var item_type: int = 0  # 0, 1, 2, or 3 based on your GameState inventory
@export var price: int = 25
@export var item_icon: Texture2D

@onready var icon_rect: TextureRect = $TextureRect
@onready var price_label: Label = $Label
@onready var buy_button: Button = $Button

func _ready() -> void:
	# Set up the visuals based on exported variables
	if item_icon:
		icon_rect.texture = item_icon
	price_label.text = "%d Coins" % price
	
	# Connect the button press to our buy function
	buy_button.pressed.connect(_on_buy_button_pressed)

func _on_buy_button_pressed() -> void:
	# 1. Check if the player can afford it
	if GameState.total_coins >= price:
		
		# 2. Deduct the coins (using your existing add_coins with a negative value)
		GameState.add_coins(-price)
		
		# 3. Add the item to the player's inventory
		GameState.add_to_inventory(item_type, 1)
		
		# 4. Make the item disappear from the shop!
		queue_free() 
	else:
		# Optional: Play a "buzzer" sound or flash the price red to show they are broke
		print("Not enough coins!")
