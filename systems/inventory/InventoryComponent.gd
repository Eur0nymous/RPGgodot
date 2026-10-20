extends Node
class_name InventoryComponent

## Инвентарь с фиксированными слотами.

signal slot_changed(index: int)
signal inventory_changed
signal item_added(item: Item, amount: int)
signal item_removed(item: Item, amount: int)

@export var slot_count: int = 20

var slots: Array = []

func _ready() -> void:
	slots.clear()
	for i in range(slot_count):
		slots.append({"item": null, "amount": 0})

func add_item(item: Item, amount: int = 1) -> bool:
	if item == null or amount <= 0:
		return false

	# Стакается
	if item.stackable:
		for i in range(slots.size()):
			var slot = slots[i]
			if slot["item"] != null and slot["item"].id == item.id:
				var max_add = item.max_stack - slot["amount"]
				var to_add = min(amount, max_add)
				if to_add > 0:
					slot["amount"] += to_add
					amount -= to_add
					slot_changed.emit(i)
				if amount <= 0:
					item_added.emit(item, 1)
					inventory_changed.emit()
					return true

	# Новый слот
	for i in range(slots.size()):
		if slots[i]["item"] == null:
			slots[i] = {"item": item, "amount": amount}
			slot_changed.emit(i)
			item_added.emit(item, amount)
			inventory_changed.emit()
			return true

	print("[Inventory] Нет места для ", item.name)
	return false

func remove_item(item_id: String, amount: int = 1) -> bool:
	for i in range(slots.size()):
		var slot = slots[i]
		if slot["item"] != null and slot["item"].id == item_id:
			return remove_item_at(i, amount)
	return false

func remove_item_at(index: int, amount: int = 1) -> bool:
	if index < 0 or index >= slots.size():
		return false
	var slot = slots[index]
	if slot["item"] == null:
		return false
	var item = slot["item"]
	slot["amount"] -= amount
	if slot["amount"] <= 0:
		slot["item"] = null
		slot["amount"] = 0
	slot_changed.emit(index)
	item_removed.emit(item, amount)
	inventory_changed.emit()
	return true

func has_item(item_id: String, amount: int = 1) -> bool:
	var total := 0
	for slot in slots:
		if slot["item"] != null and slot["item"].id == item_id:
			total += slot["amount"]
	return total >= amount

func get_item_count(item_id: String) -> int:
	var total := 0
	for slot in slots:
		if slot["item"] != null and slot["item"].id == item_id:
			total += slot["amount"]
	return total

## Считает общее количество патронов с заданным ammo_type.
func get_ammo_count(ammo_type: String) -> int:
	var total := 0
	for slot in slots:
		if slot["item"] != null and slot["item"] is Ammo:
			if slot["item"].ammo_type == ammo_type:
				total += slot["amount"]
	return total

## Удаляет патроны с заданным ammo_type. Возвращает сколько удалено.
func remove_ammo(ammo_type: String, amount: int) -> int:
	var removed := 0
	for i in range(slots.size()):
		if removed >= amount:
			break
		var slot = slots[i]
		if slot["item"] != null and slot["item"] is Ammo:
			if slot["item"].ammo_type == ammo_type:
				var can_remove: int = min(slot["amount"], amount - removed)
				slot["amount"] -= can_remove
				removed += can_remove
				if slot["amount"] <= 0:
					slot["item"] = null
					slot["amount"] = 0
				slot_changed.emit(i)
	if removed > 0:
		inventory_changed.emit()
	return removed

func swap_slots(from_index: int, to_index: int) -> void:
	if from_index < 0 or to_index < 0:
		return
	if from_index >= slots.size() or to_index >= slots.size():
		return
	var temp = slots[from_index]
	slots[from_index] = slots[to_index]
	slots[to_index] = temp
	slot_changed.emit(from_index)
	slot_changed.emit(to_index)
	inventory_changed.emit()

func to_dict() -> Dictionary:
	var result := []
	for slot in slots:
		if slot["item"] == null:
			result.append(null)
		else:
			result.append({"id": slot["item"].id, "amount": slot["amount"]})
	return {"slots": result}

func from_dict(data: Dictionary) -> void:
	var arr = data.get("slots", [])
	slots.clear()
	for i in range(slot_count):
		slots.append({"item": null, "amount": 0})

	for i in range(min(arr.size(), slots.size())):
		var entry = arr[i]
		if entry == null:
			continue
		var item_id: String = entry.get("id", "")
		var amount: int = entry.get("amount", 1)
		var item: Item = ItemDatabase.get_item(item_id)
		if item:
			slots[i] = {"item": item, "amount": amount}

	inventory_changed.emit()
