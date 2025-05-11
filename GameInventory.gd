extends Node

var currency: int = 100  # starting money
var inventory: Array[Dictionary] = []

# Sample placeholder items
const ITEM_DATABASE = {
	"flower": { "name": "Flower", "price": 20, "icon": preload("res://Item stuff/Flower_stock_photo.jpg"), "type": "gift" },
	"book": { "name": "Book", "price": 30, "icon": preload("res://Item stuff/gettyimages-157482029-612x612.jpg"), "type": "gift" }
}

func buy_item(item_id: String) -> bool:
	var item = ITEM_DATABASE.get(item_id)
	if item and currency >= item.price:
		currency -= item.price
		inventory.append(item)
		return true
	return false
