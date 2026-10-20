extends Node
class_name ChestComponent

## Хранилище сундука. Отдельный InventoryComponent.

@export var slot_count: int = 20
@export var chest_id: String = ""    # уникальный ID сундука

var inventory: InventoryComponent = null

func _ready() -> void:
	inventory = InventoryComponent.new()
	inventory.name = "ChestInventory"
	inventory.slot_count = slot_count
	add_child(inventory)

func get_inventory() -> InventoryComponent:
	return inventory

func to_dict() -> Dictionary:
	if inventory == null:
		return {}
	return inventory.to_dict()

func from_dict(data: Dictionary) -> void:
	if inventory == null:
		return
	inventory.from_dict(data)
