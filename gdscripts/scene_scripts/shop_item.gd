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
	if GameState.total_coins >= price:
		GameState.add_coins(-price)
		GameState.add_to_inventory(item_type, 1)
		
		# --- NEW WAY: Tell GameState to emit the signal ---
		GameState.reveal_furniture.emit()
		
		queue_free() 
	else:
		print("Not enough coins!")
