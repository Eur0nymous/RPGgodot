extends PanelContainer
class_name EquipmentSlot

## Слот экипировки (weapon, armor, helmet).
## Принимает drop от InventorySlot. По клику — снимает.

signal item_unequipped(slot_type: String)
signal weapon_dropped(item: Weapon)
signal armor_dropped(item: Armor)
signal helmet_dropped(item: Helmet)

@export var slot_type: String = "weapon"  # weapon, armor, helmet

var current_item: Item = null

func setup(type: String) -> void:
	slot_type = type
	_rebuild()

func set_item(item: Item) -> void:
	current_item = item
	_rebuild()

func _rebuild() -> void:
	for child in get_children():
		child.queue_free()

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.15, 0.15, 1)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.6, 0.4, 0.3, 1)
	add_theme_stylebox_override("panel", style)

	custom_minimum_size = Vector2(70, 70)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vbox)

	if current_item:
		var icon := TextureRect.new()
		if current_item.icon:
			icon.texture = current_item.icon
		icon.custom_minimum_size = Vector2(48, 48)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(icon)
	var trigger := TooltipTrigger.new()
	trigger.setup(current_item)
	trigger.set_anchors_preset(Control.PRESET_FULL_RECT)
	trigger.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(trigger)

	var lbl := Label.new()
	lbl.text = current_item.name if current_item else _default_label()
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(lbl)

func _default_label() -> String:
	match slot_type:
		"weapon": return "Оружие"
		"armor": return "Броня"
		"helmet": return "Шлем"
	return "—"

# --- Клик ---

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if current_item:
			item_unequipped.emit(slot_type)

# --- Drop ---

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	if not data.has("item"):
		return false
	var dropped_item = data["item"]
	if slot_type == "weapon":
		return dropped_item is Weapon
	if slot_type == "armor":
		return dropped_item is Armor
	if slot_type == "helmet":
		return dropped_item is Helmet
	return false

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if typeof(data) != TYPE_DICTIONARY:
		return
	var dropped_item = data["item"]
	if slot_type == "weapon" and dropped_item is Weapon:
		weapon_dropped.emit(dropped_item)
	elif slot_type == "armor" and dropped_item is Armor:
		armor_dropped.emit(dropped_item)
	elif slot_type == "helmet" and dropped_item is Helmet:
		helmet_dropped.emit(dropped_item)
