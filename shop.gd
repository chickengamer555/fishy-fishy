extends Control

@onready var money_label = $MoneyLabel
@onready var btn_flower = $VBoxContainer/btn_flower
@onready var btn_book = $VBoxContainer/btn_book

func _ready():
	btn_flower.texture_normal = GameInventory.ITEM_DATABASE["flower"].icon
	btn_book.texture_normal = GameInventory.ITEM_DATABASE["book"].icon
	update_ui()

	btn_flower.pressed.connect(func():
		GameInventory.buy_item("flower")
		update_ui()
	)

	btn_book.pressed.connect(func():
		GameInventory.buy_item("book")
		update_ui()
	)

func update_ui():
	money_label.text = "💰 Money: %d" % GameInventory.currency


func _on_map_pressed() -> void:
	get_tree().change_scene_to_file("res://Scene stuff/map.tscn")
