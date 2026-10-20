extends PanelContainer
class_name InventoryPanel

## Панель инвентаря. Сама принимает drop вне слотов — выброс предмета.

signal item_dropped_outside(item: Item, amount: int)

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	if not data.has("item"):
		return false
	return true

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if typeof(data) != TYPE_DICTIONARY:
		return
	var item: Item = data["item"]
	var amount: int = data.get("amount", 1)
	item_dropped_outside.emit(item, amount)
