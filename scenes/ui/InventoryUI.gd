extends CanvasLayer

## UI инвентаря: сумка + экипировка. Drag & drop.
## Клик по оружию в сумке → в хотбар (удаляя из инвентаря).
## Снятие оружия из экипировки → возврат в инвентарь через Player.unequip_weapon.
## Гранаты — вся стопка уходит в хотбар, current_ammo = количество.

@onready var item_grid: GridContainer = get_node_or_null("Panel/MarginContainer/VBoxContainer/MainHBox/InventorySection/ItemGrid")
@onready var equip_grid: GridContainer = get_node_or_null("Panel/MarginContainer/VBoxContainer/MainHBox/EquipmentSection/EquipmentGrid")
@onready var weapon_slot_ui: PanelContainer = get_node_or_null("Panel/MarginContainer/VBoxContainer/MainHBox/EquipmentSection/EquipmentGrid/WeaponSlotUI")
@onready var armor_slot_ui: PanelContainer = get_node_or_null("Panel/MarginContainer/VBoxContainer/MainHBox/EquipmentSection/EquipmentGrid/ArmorSlotUI")
@onready var helmet_slot_ui: PanelContainer = get_node_or_null("Panel/MarginContainer/VBoxContainer/MainHBox/EquipmentSection/EquipmentGrid/HelmetSlotUI")
@onready var panel: PanelContainer = get_node_or_null("Panel")

var player_inventory: InventoryComponent = null
var player: Node = null
var is_open: bool = false

func _ready() -> void:
	visible = false
	if item_grid == null:
		push_error("[InventoryUI] item_grid не найден")
		return

	await get_tree().process_frame

	if weapon_slot_ui and weapon_slot_ui.has_method("setup"):
		weapon_slot_ui.setup("weapon")
		if weapon_slot_ui.has_signal("weapon_dropped"):
			weapon_slot_ui.weapon_dropped.connect(_on_weapon_dropped_to_equipment)
		if weapon_slot_ui.has_signal("item_unequipped"):
			weapon_slot_ui.item_unequipped.connect(_on_equipment_unequip)

	if armor_slot_ui and armor_slot_ui.has_method("setup"):
		armor_slot_ui.setup("armor")
		if armor_slot_ui.has_signal("armor_dropped"):
			armor_slot_ui.armor_dropped.connect(_on_armor_dropped)
		if armor_slot_ui.has_signal("item_unequipped"):
			armor_slot_ui.item_unequipped.connect(_on_equipment_unequip)

	if helmet_slot_ui and helmet_slot_ui.has_method("setup"):
		helmet_slot_ui.setup("helmet")
		if helmet_slot_ui.has_signal("helmet_dropped"):
			helmet_slot_ui.helmet_dropped.connect(_on_helmet_dropped)
		if helmet_slot_ui.has_signal("item_unequipped"):
			helmet_slot_ui.item_unequipped.connect(_on_equipment_unequip)

	if panel and panel.has_signal("item_dropped_outside"):
		panel.item_dropped_outside.connect(_on_item_dropped)

	GameManager.game_paused.connect(_on_game_paused)

	player = get_tree().get_first_node_in_group("player")
	if player:
		player_inventory = player.get_node_or_null("InventoryComponent")
		if player_inventory:
			player_inventory.slot_changed.connect(_on_slot_changed)
			player_inventory.inventory_changed.connect(_refresh_all)
		if player.has_signal("weapon_equipped"):
			player.weapon_equipped.connect(_on_weapon_equipped)
		if player.has_signal("armor_equipped"):
			player.armor_equipped.connect(_on_armor_or_helmet_equipped)
		if player.has_signal("helmet_equipped"):
			player.helmet_equipped.connect(_on_armor_or_helmet_equipped)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_inventory"):
		if GameManager.is_paused:
			return
		toggle()

func toggle() -> void:
	if GameManager.is_paused:
		return
	is_open = not is_open
	visible = is_open
	if is_open:
		_refresh_all()

func _on_game_paused(is_paused: bool) -> void:
	if is_paused and is_open:
		is_open = false
		visible = false

func _refresh_all() -> void:
	if player_inventory == null or item_grid == null:
		return

	for child in item_grid.get_children():
		child.queue_free()

	for i in range(player_inventory.slots.size()):
		var slot_data = player_inventory.slots[i]
		var slot := InventorySlot.new()
		slot.setup(i, slot_data["item"], slot_data["amount"])
		slot.slot_clicked.connect(_on_slot_clicked)
		slot.slot_dropped.connect(_on_slot_dropped)
		item_grid.add_child(slot)

	_refresh_equipment()

func _on_slot_changed(_index: int) -> void:
	_refresh_all()

func _on_slot_dropped(from_index: int, to_index: int) -> void:
	if player_inventory == null:
		return
	player_inventory.swap_slots(from_index, to_index)
	print("[Inventory] Swap ", from_index, " ↔ ", to_index)

## Клик по слоту сумки. Оружие (без Shift) → в хотбар.
func _on_slot_clicked(index: int, with_shift: bool) -> void:
	if player_inventory == null or player == null:
		return
	var slot_data = player_inventory.slots[index]
	if slot_data["item"] == null:
		return
	var item = slot_data["item"]

	if item is Weapon and not with_shift:
		_add_to_hotbar(index, item)

## Оружие из инвентаря → в хотбар.
## Для гранат — вся стопка (current_ammo = количество).
func _add_to_hotbar(inv_index: int, weapon: Weapon) -> void:
	var hotbar = player.get_node_or_null("HotbarComponent")
	if hotbar == null:
		print("[Inventory] HotbarComponent нет")
		return
	var free: int = hotbar.find_free_slot()
	if free < 0:
		print("[Inventory] Хотбар полон")
		return

	# Граната — берём всё количество
	if weapon is Grenade:
		var count: int = player_inventory.get_item_count(weapon.id)
		if count <= 0:
			return
		player_inventory.remove_item(weapon.id, count)
		weapon.current_ammo = count
		hotbar.set_slot(free, weapon)
		print("[Inventory] Гранат x", count, " → хотбар слот ", free + 1)
	else:
		player_inventory.remove_item_at(inv_index, 1)
		hotbar.set_slot(free, weapon)
		print("[Inventory] ", weapon.name, " → хотбар слот ", free + 1)

	_refresh_all()

## Экипировка по drag в слот оружия (из сумки). Не из хотбара — из сумки.
func _equip_weapon_from_slot(index: int) -> void:
	if player_inventory == null or player == null:
		return
	var slot_data = player_inventory.slots[index]
	var item = slot_data["item"]
	if not (item is Weapon):
		return

	# Убираем из инвентаря
	player_inventory.remove_item_at(index, 1)

	# Если в руках было другое оружие — вернуть его в инвентарь
	if player.equipped_weapon and player.equipped_weapon != item:
		player_inventory.add_item(player.equipped_weapon, 1)
		# И удалить из хотбара, если там было
		var hotbar = player.get_node_or_null("HotbarComponent")
		if hotbar:
			var idx = hotbar.find_slot_of(player.equipped_weapon)
			if idx >= 0:
				hotbar.clear_slot(idx)

	player.equip_weapon(item)
	print("[Inventory] Экипировано: ", item.name)

func _equip_armor_from_slot(index: int) -> void:
	if player_inventory == null or player == null:
		return
	var slot_data = player_inventory.slots[index]
	var item = slot_data["item"]
	if not (item is Armor):
		return
	player_inventory.remove_item_at(index, 1)
	if player.equipped_armor:
		player_inventory.add_item(player.equipped_armor, 1)
	player.equip_armor(item)
	print("[Inventory] Экипирована броня: ", item.name)

func _equip_helmet_from_slot(index: int) -> void:
	if player_inventory == null or player == null:
		return
	var slot_data = player_inventory.slots[index]
	var item = slot_data["item"]
	if not (item is Helmet):
		return
	player_inventory.remove_item_at(index, 1)
	if player.equipped_helmet:
		player_inventory.add_item(player.equipped_helmet, 1)
	player.equip_helmet(item)
	print("[Inventory] Экипирован шлем: ", item.name)

func _on_weapon_dropped_to_equipment(weapon: Weapon) -> void:
	if player_inventory == null or player == null:
		return
	var from_index := -1
	for i in range(player_inventory.slots.size()):
		var slot = player_inventory.slots[i]
		if slot["item"] == weapon:
			from_index = i
			break
	if from_index < 0:
		return
	_equip_weapon_from_slot(from_index)
	_refresh_all()

func _on_armor_dropped(armor: Armor) -> void:
	if player_inventory == null or player == null:
		return
	var from_index := -1
	for i in range(player_inventory.slots.size()):
		var slot = player_inventory.slots[i]
		if slot["item"] == armor:
			from_index = i
			break
	if from_index < 0:
		return
	_equip_armor_from_slot(from_index)
	_refresh_all()

func _on_helmet_dropped(helmet: Helmet) -> void:
	if player_inventory == null or player == null:
		return
	var from_index := -1
	for i in range(player_inventory.slots.size()):
		var slot = player_inventory.slots[i]
		if slot["item"] == helmet:
			from_index = i
			break
	if from_index < 0:
		return
	_equip_helmet_from_slot(from_index)
	_refresh_all()

## Снятие через клик по слоту экипировки.
## Для оружия — используем Player.unequip_weapon() (сам вернёт в инвентарь и уберёт из хотбара).
func _on_equipment_unequip(slot_type: String) -> void:
	if player == null or player_inventory == null:
		return
	if slot_type == "weapon":
		if player.equipped_weapon:
			player.unequip_weapon()
			_refresh_all()
	elif slot_type == "armor" and player.equipped_armor:
		if player_inventory.add_item(player.equipped_armor, 1):
			player.equip_armor(null)
			_refresh_all()
	elif slot_type == "helmet" and player.equipped_helmet:
		if player_inventory.add_item(player.equipped_helmet, 1):
			player.equip_helmet(null)
			_refresh_all()

func _on_weapon_equipped(_weapon: Weapon) -> void:
	if is_open:
		_refresh_equipment()

func _on_armor_or_helmet_equipped(_item: Item) -> void:
	if is_open:
		_refresh_equipment()

func _refresh_equipment() -> void:
	if player and "equipped_weapon" in player and weapon_slot_ui and weapon_slot_ui.has_method("set_item"):
		weapon_slot_ui.set_item(player.equipped_weapon)
	if player and "equipped_armor" in player and armor_slot_ui and armor_slot_ui.has_method("set_item"):
		armor_slot_ui.set_item(player.equipped_armor)
	if player and "equipped_helmet" in player and helmet_slot_ui and helmet_slot_ui.has_method("set_item"):
		helmet_slot_ui.set_item(player.equipped_helmet)

func _on_item_dropped(item: Item, amount: int) -> void:
	if player_inventory == null or player == null:
		return
	player_inventory.remove_item(item.id, amount)
	_spawn_pickup(item, amount)

func _spawn_pickup(item: Item, amount: int) -> void:
	var pickup_scene := load("res://systems/interaction/PickupItem.tscn")
	if pickup_scene == null:
		return
	var pickup = pickup_scene.instantiate()
	pickup.item = item
	pickup.amount = amount

	var forward: Vector3 = -player.global_transform.basis.z
	forward.y = 0
	forward = forward.normalized()
	var spawn_pos: Vector3 = player.global_position + forward * 1.5 + Vector3.UP * 1.0

	player.get_tree().current_scene.add_child(pickup)
	pickup.global_position = spawn_pos
	print("[Inventory] Выброшено: ", item.name, " x", amount)
