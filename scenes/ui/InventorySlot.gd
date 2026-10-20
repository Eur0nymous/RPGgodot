extends PanelContainer
class_name InventorySlot

signal slot_clicked(index: int, with_shift: bool)
signal slot_dropped(from_index: int, to_index: int)

var index: int = -1
var item: Item = null
var amount: int = 0

func setup(slot_index: int, slot_item: Item, slot_amount: int) -> void:
	index = slot_index
	item = slot_item
	amount = slot_amount
	_rebuild()

func _rebuild() -> void:
	for child in get_children():
		child.queue_free()

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 1) if item == null else Color(0.25, 0.25, 0.3, 1)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.4, 0.4, 0.5, 1)
	add_theme_stylebox_override("panel", style)

	custom_minimum_size = Vector2(60, 60)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vbox)

	if item != null:
		var icon := TextureRect.new()
		if item.icon:
			icon.texture = item.icon
		icon.custom_minimum_size = Vector2(36, 36)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(icon)

		if amount > 1:
			var qty := Label.new()
			qty.text = str(amount)
			qty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			qty.add_theme_font_size_override("font_size", 10)
			qty.mouse_filter = Control.MOUSE_FILTER_IGNORE
			vbox.add_child(qty)

	# Тултип
	var trigger := TooltipTrigger.new()
	trigger.setup(item)
	trigger.set_anchors_preset(Control.PRESET_FULL_RECT)
	trigger.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(trigger)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var shift := Input.is_key_pressed(KEY_SHIFT)
		slot_clicked.emit(index, shift)

func _get_drag_data(_at_position: Vector2) -> Variant:
	if item == null:
		return null

	var preview_panel := PanelContainer.new()
	preview_panel.custom_minimum_size = Vector2(48, 48)
	var preview_style := StyleBoxFlat.new()
	preview_style.bg_color = Color(0.3, 0.3, 0.4, 0.85)
	preview_style.border_width_left = 2
	preview_style.border_width_right = 2
	preview_style.border_width_top = 2
	preview_style.border_width_bottom = 2
	preview_style.border_color = Color(0.7, 0.7, 0.9, 1)
	preview_panel.add_theme_stylebox_override("panel", preview_style)

	if item.icon:
		var icon := TextureRect.new()
		icon.texture = item.icon
		icon.custom_minimum_size = Vector2(48, 48)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		preview_panel.add_child(icon)

	var wrapper := Control.new()
	wrapper.custom_minimum_size = Vector2(48, 48)
	wrapper.add_child(preview_panel)
	set_drag_preview(wrapper)

	return {"from_index": index, "item": item, "amount": amount}

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	if not data.has("from_index"):
		return false
	return data["from_index"] != index

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if typeof(data) != TYPE_DICTIONARY:
		return
	var from_index: int = data["from_index"]
	slot_dropped.emit(from_index, index)
