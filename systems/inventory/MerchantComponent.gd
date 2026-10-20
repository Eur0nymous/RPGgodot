extends Node
class_name MerchantComponent

## Товары торговца.

signal stock_changed

@export var merchant_id: String = ""    # уникальный ID торговца
@export var items_for_sale: Array[Item] = []
@export var markup: float = 1.5
@export var buyback: float = 0.5

var stock: Dictionary = {}   # id → amount

func _ready() -> void:
	for item in items_for_sale:
		if item:
			stock[item.id] = 10

func get_price(item: Item) -> int:
	if item == null:
		return 0
	return int(item.price * markup)

func get_buyback_price(item: Item) -> int:
	if item == null:
		return 0
	return int(item.price * buyback)

func has_stock(item: Item, amount: int = 1) -> bool:
	if item == null:
		return false
	return stock.get(item.id, 0) >= amount

func remove_from_stock(item: Item, amount: int = 1) -> bool:
	if not has_stock(item, amount):
		return false
	stock[item.id] -= amount
	stock_changed.emit()
	return true

func add_to_stock(item: Item, amount: int = 1) -> void:
	stock[item.id] = stock.get(item.id, 0) + amount
	stock_changed.emit()

func get_stock(item: Item) -> int:
	return stock.get(item.id, 0)

func to_dict() -> Dictionary:
	return {"stock": stock.duplicate()}

func from_dict(data: Dictionary) -> void:
	stock.clear()
	var s = data.get("stock", {})
	for k in s:
		stock[k] = int(s[k])
	stock_changed.emit()
