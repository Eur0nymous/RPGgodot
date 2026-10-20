extends Node
class_name HotbarComponent

## Хотбар: 9 слотов. Хранит ссылки на Weapon (не копии).

signal slot_changed(index: int)

@export var slot_count: int = 9

var slots: Array = []   # [Weapon | null, ...]

func _ready() -> void:
	slots.clear()
	for i in range(slot_count):
		slots.append(null)

func set_slot(index: int, weapon: Weapon) -> void:
	if index < 0 or index >= slot_count:
		return
	slots[index] = weapon
	slot_changed.emit(index)
	print("[Hotbar] Слот ", index + 1, " = ", weapon.name if weapon else "пусто")

func get_slot(index: int) -> Weapon:
	if index < 0 or index >= slot_count:
		return null
	return slots[index]

func clear_slot(index: int) -> void:
	if index < 0 or index >= slot_count:
		return
	slots[index] = null
	slot_changed.emit(index)

func find_free_slot() -> int:
	for i in range(slot_count):
		if slots[i] == null:
			return i
	return -1

## Найти слот, где лежит этот Weapon
func find_slot_of(weapon: Weapon) -> int:
	for i in range(slot_count):
		if slots[i] == weapon:
			return i
	return -1

func to_dict() -> Dictionary:
	var result := []
	for w in slots:
		if w == null:
			result.append(null)
		else:
			result.append(w.id)
	return {"slots": result}

func from_dict(data: Dictionary) -> void:
	var arr = data.get("slots", [])
	for i in range(slot_count):
		if i < arr.size() and arr[i] != null:
			var item = ItemDatabase.get_item(arr[i])
			slots[i] = item as Weapon
		else:
			slots[i] = null
		slot_changed.emit(i)
