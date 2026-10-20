extends Interactable
class_name Chest

## Сундук. F открывает UI. F закрывает (в UI).
## Регистрируется в группе chest_ui при открытии.

@onready var chest_inv: ChestComponent = get_node_or_null("ChestComponent")

var ui_open: bool = false

func _ready() -> void:
	add_to_group("chest")

func interact(player: Node) -> void:
	if ui_open:
		return
	ui_open = true
	print("[Chest] Открыт: ", name)

	var ui_scene := load("res://scenes/ui/ChestUI.tscn")
	if ui_scene == null:
		push_warning("[Chest] Нет ChestUI.tscn")
		ui_open = false
		return
	var ui = ui_scene.instantiate()
	get_tree().current_scene.add_child(ui)
	ui.open(self, player)

func close_ui() -> void:
	ui_open = false
	print("[Chest] Закрыт: ", name)

func get_inventory() -> InventoryComponent:
	if chest_inv:
		return chest_inv.get_inventory()
	return null
