extends CanvasLayer

## UI торговца. Клик — продать/купить 1 шт. Ctrl+клик — весь стак.
## Закрытие — F или пауза.

@onready var player_grid: GridContainer = $Panel/MarginContainer/VBoxContainer/HBoxContainer/PlayerSection/PlayerGrid
@onready var merchant_grid: GridContainer = $Panel/MarginContainer/VBoxContainer/HBoxContainer/MerchantSection/MerchantGrid
@onready var money_label: Label = $Panel/MarginContainer/VBoxContainer/MoneyLabel

var merchant: Merchant = null
var player: Node = null
var player_inv: InventoryComponent = null
var player_wallet: WalletComponent = null
var merchant_comp: MerchantComponent = null

var _just_opened: bool = false

func _ready() -> void:
	visible = false
	add_to_group("merchant_ui")
	GameManager.game_paused.connect(_on_game_paused)

func _on_game_paused(is_paused: bool) -> void:
	if is_paused:
		close()

func open(merchant_node: Merchant, player_node: Node) -> void:
	merchant = merchant_node
	player = player_node
	player_inv = player.get_node_or_null("InventoryComponent")
	player_wallet = player.get_node_or_null("WalletComponent")
	merchant_comp = merchant.get_merchant()

	if player_inv:
		player_inv.inventory_changed.connect(_refresh)
	if player_wallet:
		player_wallet.money_changed.connect(_on_money_changed)
	if merchant_comp:
		merchant_comp.stock_changed.connect(_refresh)

	visible = true
	_refresh()

	_just_opened = true
	await get_tree().process_frame
	_just_opened = false

func close() -> void:
	visible = false
	remove_from_group("merchant_ui")
	if merchant:
		merchant.close_ui()
	queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if _just_opened:
		return
	if event.is_action_pressed("interact"):
		close()

func _on_money_changed(_amount: int) -> void:
	_update_money_label()

func _update_money_label() -> void:
	if player_wallet:
		money_label.text = "Деньги: " + str(player_wallet.money)
	else:
		money_label.text = "Деньги: —"

func _refresh() -> void:
	_clear_grid(player_grid)
	_clear_grid(merchant_grid)
	_update_money_label()

	if player_inv:
		for i in range(player_inv.slots.size()):
			var slot_data = player_inv.slots[i]
			var price: int = 0
			if slot_data["item"] and merchant_comp:
				price = merchant_comp.get_buyback_price(slot_data["item"])
			var slot := _create_slot(slot_data["item"], slot_data["amount"], price)
			slot.gui_input.connect(_on_player_slot_click.bind(i))
			player_grid.add_child(slot)

	if merchant_comp:
		for item in merchant_comp.items_for_sale:
			if item == null:
				continue
			var stock: int = merchant_comp.get_stock(item)
			var price: int = merchant_comp.get_price(item)
			var slot := _create_slot(item, stock, price)
			slot.gui_input.connect(_on_merchant_slot_click.bind(item))
			merchant_grid.add_child(slot)

func _clear_grid(grid: GridContainer) -> void:
	for c in grid.get_children():
		c.queue_free()

func _create_slot(item: Item, amount: int, price: int) -> PanelContainer:
	var slot := PanelContainer.new()
	slot.custom_minimum_size = Vector2(60, 60)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 1) if item == null else Color(0.25, 0.25, 0.3, 1)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.4, 0.4, 0.5, 1)
	slot.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	slot.add_child(vbox)

	if item == null:
		return slot

	if item.icon:
		var icon := TextureRect.new()
		icon.texture = item.icon
		icon.custom_minimum_size = Vector2(36, 36)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(icon)

	if amount > 1:
		var amt := Label.new()
		amt.text = "x" + str(amount)
		amt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		amt.add_theme_font_size_override("font_size", 10)
		amt.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(amt)

	if price >= 0:
		var lbl := Label.new()
		lbl.text = str(price) + " ₽"
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 10)
		lbl.modulate = Color(1, 0.9, 0.4)
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(lbl)

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
	if player_inv == null or merchant_comp == null or player_wallet == null:
		return
	var slot = player_inv.slots[index]
	if slot["item"] == null:
		return
	var item = slot["item"]
	var buyback: int = merchant_comp.get_buyback_price(item)
	if buyback <= 0:
		print("[Merchant] Нельзя продать")
		return

	var ctrl := Input.is_key_pressed(KEY_CTRL)
	var amount_to_sell: int = slot["amount"] if ctrl else 1
	var total_price: int = buyback * amount_to_sell

	player_inv.remove_item_at(index, amount_to_sell)
	player_wallet.add(total_price)
	merchant_comp.add_to_stock(item, amount_to_sell)
	print("[Merchant] Продано: ", item.name, " x", amount_to_sell, " за ", total_price)
	_refresh()

func _on_merchant_slot_click(event: InputEvent, item: Item) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if player_inv == null or merchant_comp == null or player_wallet == null:
		return

	var stock: int = merchant_comp.get_stock(item)
	if stock <= 0:
		print("[Merchant] Нет в наличии")
		return

	var price: int = merchant_comp.get_price(item)
	if price <= 0:
		print("[Merchant] Цена = 0")
		return

	var ctrl := Input.is_key_pressed(KEY_CTRL)
	var amount_to_buy: int = 1
	if ctrl:
		var affordable: int = player_wallet.money / price
		amount_to_buy = min(stock, affordable)
		if amount_to_buy <= 0:
			print("[Merchant] Недостаточно денег")
			return

	var total_price: int = price * amount_to_buy
	if not player_wallet.can_afford(total_price):
		print("[Merchant] Недостаточно денег")
		return

	player_wallet.spend(total_price)
	merchant_comp.remove_from_stock(item, amount_to_buy)
	player_inv.add_item(item, amount_to_buy)
	print("[Merchant] Куплено: ", item.name, " x", amount_to_buy, " за ", total_price)
	_refresh()
