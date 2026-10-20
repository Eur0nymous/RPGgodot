extends Control
class_name DropZone

## Зона выброса. Принимает drop вне слотов — спавнит предмет в мире.

signal item_dropped(item: Item, amount: int)

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
	item_dropped.emit(item, amount)
