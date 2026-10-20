extends CanvasLayer

## HUD: HP, подсказка, текущее оружие (с патронами/количеством),
## трекер квестов, деньги.

@onready var prompt: Label = $InteractionPrompt
@onready var health_bar: ProgressBar = $HealthBar
@onready var health_label: Label = $HealthLabel
@onready var cast_label: Label = $CastLabel
@onready var weapon_icon: TextureRect = $WeaponSlot/HBoxContainer/WeaponIcon
@onready var weapon_name: Label = $WeaponSlot/HBoxContainer/WeaponName
@onready var quest_tracker: Label = $QuestTracker
@onready var money_label: Label = $MoneyLabel

var player_health: HealthComponent = null
var player_wallet: WalletComponent = null

func _ready() -> void:
	prompt.visible = false
	health_bar.value = 100
	health_label.text = "100 / 100"
	cast_label.text = "Каста: —"
	weapon_name.text = "—"
	money_label.text = "0 ₽"

	QuestManager.quest_started.connect(_on_quests_changed)
	QuestManager.quest_ready_to_turn_in.connect(_on_quests_changed)
	QuestManager.quest_completed.connect(_on_quests_changed)
	_update_quest_tracker()

	await get_tree().process_frame
	var player = get_tree().get_first_node_in_group("player")
	if player:
		# HP
		player_health = player.get_node_or_null("HealthComponent")
		if player_health:
			player_health.damaged.connect(_on_health_changed)
			player_health.healed.connect(_on_health_changed)
			_update_health(player_health.current_health, player_health.max_health)

		# Оружие
		if player.has_signal("weapon_equipped"):
			player.weapon_equipped.connect(set_weapon)
			if "equipped_weapon" in player:
				set_weapon(player.equipped_weapon)

		# Деньги
		player_wallet = player.get_node_or_null("WalletComponent")
		if player_wallet:
			player_wallet.money_changed.connect(_on_money_changed)
			_on_money_changed(player_wallet.money)

func show_prompt(text: String) -> void:
	prompt.text = text
	prompt.visible = true

func hide_prompt() -> void:
	prompt.visible = false

func _on_health_changed(_amount: int, current: int, max_hp: int) -> void:
	_update_health(current, max_hp)

func _update_health(current: int, max_hp: int) -> void:
	health_bar.max_value = max_hp
	health_bar.value = current
	health_label.text = str(current) + " / " + str(max_hp)

func set_cast(cast_name: String) -> void:
	cast_label.text = "Каста: " + cast_name

func set_weapon(weapon: Weapon) -> void:
	if weapon == null:
		weapon_icon.texture = null
		weapon_name.text = "—"
		return

	weapon_icon.texture = weapon.icon
	var text := weapon.name

	# Граната — количество в инвентаре
	if weapon is Grenade:
		var player = get_tree().get_first_node_in_group("player")
		if player:
			var inv = player.get_node_or_null("InventoryComponent")
			if inv:
				var count: int = inv.get_item_count(weapon.id)
				text += " × " + str(count)

	# Ranged — патроны в магазине
	elif weapon is RangedWeapon and weapon.magazine_size > 0:
		text += " (" + str(weapon.current_ammo) + "/" + str(weapon.magazine_size) + ")"

	weapon_name.text = text

func _on_money_changed(amount: int) -> void:
	money_label.text = str(amount) + " ₽"

func _on_quests_changed(_q: Quest) -> void:
	_update_quest_tracker()

func _update_quest_tracker() -> void:
	var text := ""
	for q in QuestManager.active_quests:
		text += "• " + q.title + "\n"
	for q in QuestManager.ready_quests:
		text += "ВЫПОЛНЕНО " + q.title + " — сдать\n"
	quest_tracker.text = text
