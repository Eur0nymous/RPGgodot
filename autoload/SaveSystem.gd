extends Node

signal game_saved(slot: int)
signal game_loaded(slot: int)

const SAVE_PATH := "user://save_%d.json"

func _ready() -> void:
	print("[SaveSystem] Ready")

func save_game(slot: int = 0) -> void:
	var player := get_tree().get_first_node_in_group("player")
	var player_pos := Vector3.ZERO
	var player_data := {}

	if player:
		player_pos = player.global_position

		# Инвентарь
		var inv = player.get_node_or_null("InventoryComponent")
		if inv:
			player_data["inventory"] = inv.to_dict()

		# Хотбар
		var hotbar = player.get_node_or_null("HotbarComponent")
		if hotbar:
			player_data["hotbar"] = hotbar.to_dict()

		# Деньги
		var wallet = player.get_node_or_null("WalletComponent")
		if wallet:
			player_data["wallet"] = wallet.to_dict()

		# Экипировка + патроны в экипированном
		var weapon_id := ""
		var weapon_ammo := 0
		if player.equipped_weapon:
			weapon_id = player.equipped_weapon.id
			weapon_ammo = player.equipped_weapon.current_ammo
		var armor_id := ""
		if player.equipped_armor:
			armor_id = player.equipped_armor.id
		var helmet_id := ""
		if player.equipped_helmet:
			helmet_id = player.equipped_helmet.id

		player_data["weapon"] = weapon_id
		player_data["weapon_ammo"] = weapon_ammo
		player_data["armor"] = armor_id
		player_data["helmet"] = helmet_id

		# HP
		var health = player.get_node_or_null("HealthComponent")
		if health:
			player_data["health"] = health.current_health

	# Собираем сундуки и торговцев по всей сцене
	var chests := _collect_chests()
	var merchants := _collect_merchants()

	var data := {
		"flags": FlagManager.to_dict(),
		"quests": QuestManager.to_dict(),
		"player_position": [player_pos.x, player_pos.y, player_pos.z],
		"player": player_data,
		"chests": chests,
		"merchants": merchants,
		"timestamp": Time.get_datetime_string_from_system(),
		"version": 1
	}
	var path := SAVE_PATH % slot
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
		print("[SaveSystem] Saved to ", path)
		game_saved.emit(slot)
	else:
		push_error("[SaveSystem] Cannot save to ", path)

func _collect_chests() -> Dictionary:
	var result := {}
	for node in get_tree().get_nodes_in_group("chest"):
		var chest = node
		var comp = chest.get_node_or_null("ChestComponent")
		if comp == null:
			continue
		if comp.chest_id == "":
			continue
		result[comp.chest_id] = comp.to_dict()
	return result

func _collect_merchants() -> Dictionary:
	var result := {}
	for node in get_tree().get_nodes_in_group("merchant"):
		var merchant = node
		var comp = merchant.get_node_or_null("MerchantComponent")
		if comp == null:
			continue
		if comp.merchant_id == "":
			continue
		result[comp.merchant_id] = comp.to_dict()
	return result

func load_game(slot: int = 0) -> bool:
	var path := SAVE_PATH % slot
	if not FileAccess.file_exists(path):
		push_warning("[SaveSystem] No save at ", path)
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("[SaveSystem] Cannot read ", path)
		return false
	var json_text := file.get_as_text()
	file.close()
	var data = JSON.parse_string(json_text)
	if typeof(data) != TYPE_DICTIONARY:
		push_error("[SaveSystem] Invalid save data")
		return false

	# Флаги
	FlagManager.from_dict(data.get("flags", {}))

	# Игрок
	var player := get_tree().get_first_node_in_group("player")
	if player:
		if data.has("player_position"):
			var p = data["player_position"]
			player.global_position = Vector3(p[0], p[1], p[2])

		var player_data: Dictionary = data.get("player", {})

		# Инвентарь
		var inv = player.get_node_or_null("InventoryComponent")
		if inv and player_data.has("inventory"):
			inv.from_dict(player_data["inventory"])

		# Хотбар
		var hotbar = player.get_node_or_null("HotbarComponent")
		if hotbar and player_data.has("hotbar"):
			hotbar.from_dict(player_data["hotbar"])

		# Деньги
		var wallet = player.get_node_or_null("WalletComponent")
		if wallet and player_data.has("wallet"):
			wallet.from_dict(player_data["wallet"])

		# Экипировка
		var weapon_id: String = player_data.get("weapon", "")
		var weapon_ammo: int = int(player_data.get("weapon_ammo", 0))
		var armor_id: String = player_data.get("armor", "")
		var helmet_id: String = player_data.get("helmet", "")

		if weapon_id != "":
			var weapon: Weapon = ItemDatabase.get_item(weapon_id) as Weapon
			if weapon:
				weapon.current_ammo = weapon_ammo
				player.equip_weapon(weapon)
			else:
				player.equip_weapon(null)
		else:
			player.equip_weapon(null)

		if armor_id != "":
			player.equip_armor(ItemDatabase.get_item(armor_id) as Armor)
		else:
			player.equip_armor(null)

		if helmet_id != "":
			player.equip_helmet(ItemDatabase.get_item(helmet_id) as Helmet)
		else:
			player.equip_helmet(null)

		# HP
		var health = player.get_node_or_null("HealthComponent")
		if health and player_data.has("health"):
			health.current_health = int(player_data["health"])
			health.damaged.emit(0, health.current_health, health.max_health)

	# Сундуки
	_restore_chests(data.get("chests", {}))
	# Торговцы
	_restore_merchants(data.get("merchants", {}))

	# Квесты
	QuestManager.from_dict(data.get("quests", {}))

	print("[SaveSystem] Loaded from ", path)
	game_loaded.emit(slot)
	return true

func _restore_chests(data: Dictionary) -> void:
	for node in get_tree().get_nodes_in_group("chest"):
		var comp = node.get_node_or_null("ChestComponent")
		if comp == null:
			continue
		if comp.chest_id == "":
			continue
		if data.has(comp.chest_id):
			comp.from_dict(data[comp.chest_id])

func _restore_merchants(data: Dictionary) -> void:
	for node in get_tree().get_nodes_in_group("merchant"):
		var comp = node.get_node_or_null("MerchantComponent")
		if comp == null:
			continue
		if comp.merchant_id == "":
			continue
		if data.has(comp.merchant_id):
			comp.from_dict(data[comp.merchant_id])

func has_save(slot: int = 0) -> bool:
	return FileAccess.file_exists(SAVE_PATH % slot)
