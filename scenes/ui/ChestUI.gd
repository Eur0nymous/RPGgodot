extends CanvasLayer

## UI сундука. Инвентарь игрока слева, сундука справа.
## Клик по предмету — перенос в другую сторону.
## Закрытие — F (interact).
## Защита от закрытия в первом кадре после открытия.

@onready var player_grid: GridContainer = $Panel/MarginContainer/VBoxContainer/HBoxContainer/PlayerSection/PlayerGrid
@onready var chest_grid: GridContainer = $Panel/MarginContainer/VBoxContainer/HBoxContainer/ChestSection/ChestGrid

var chest: Chest = null
var player: Node = null
var player_inv: InventoryComponent = null
var chest_inv: InventoryComponent = null

var _just_opened: bool = false

func _ready() -> void:
	visible = false
	add_to_group("chest_ui")

func open(chest_node: Chest, player_node: Node) -> void:
	chest = chest_node
	player = player_node
	player_inv = player.get_node_or_null("InventoryComponent")
	chest_inv = chest.get_inventory()

	if player_inv:
		player_inv.inventory_changed.connect(_refresh)
	if chest_inv:
		chest_inv.inventory_changed.connect(_refresh)

	visible = true
	_refresh()

	# Защита от закрытия в первом кадре
	_just_opened = true
	await get_tree().process_frame
	_just_opened = false

func close() -> void:
	visible = false
	remove_from_group("chest_ui")
	if chest:
		chest.close_ui()
	queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if _just_opened:
		return
	if event.is_action_pressed("interact"):
		close()

func _refresh() -> void:
	_clear_grid(player_grid)
	_clear_grid(chest_grid)

	if player_inv:
		for i in range(player_inv.slots.size()):
			var slot_data = player_inv.slots[i]
			var slot := _create_slot(slot_data["item"], slot_data["amount"])
			slot.gui_input.connect(_on_player_slot_click.bind(i))
			player_grid.add_child(slot)

	if chest_inv:
		for i in range(chest_inv.slots.size()):
			var slot_data = chest_inv.slots[i]
			var slot := _create_slot(slot_data["item"], slot_data["amount"])
			slot.gui_input.connect(_on_chest_slot_click.bind(i))
			chest_grid.add_child(slot)

func _clear_grid(grid: GridContainer) -> void:
	for c in grid.get_children():
		c.queue_free()

func _create_slot(item: Item, amount: int) -> PanelContainer:
	var slot := PanelContainer.new()
	slot.custom_minimum_size = Vector2(50, 50)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 1) if item == null else Color(0.25, 0.25, 0.3, 1)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.4, 0.4, 0.5, 1)
	slot.add_theme_stylebox_override("panel", style)

	if item and item.icon:
		var icon := TextureRect.new()
		icon.texture = item.icon
		icon.custom_minimum_size = Vector2(40, 40)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(icon)
	# Тултип
	var trigger := TooltipTrigger.new()
	trigger.setup(item)
	trigger.set_anchors_preset(Control.PRESET_FULL_RECT)
	trigger.mouse_filter = Control.MOUSE_FILTER_PASS
	slot.add_child(trigger)
	return slot

func _on_player_slot_click(event: InputEvent, index: int) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if player_inv == null or chest_inv == null:
		return
	var slot = player_inv.slots[index]
	if slot["item"] == null:
		return
	var item = slot["item"]
	var amount = slot["amount"]
	player_inv.remove_item_at(index, amount)
	chest_inv.add_item(item, amount)
	print("[Chest] ", item.name, " → сундук")
	_refresh()

func _on_chest_slot_click(event: InputEvent, index: int) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if player_inv == null or chest_inv == null:
		return
	var slot = chest_inv.slots[index]
	if slot["item"] == null:
		return
	var item = slot["item"]
	var amount = slot["amount"]
	chest_inv.remove_item_at(index, amount)
	player_inv.add_item(item, amount)
	print("[Chest] ", item.name, " → игрок")
	_refresh()
