extends CanvasLayer

## Хотбар. 9 слотов. Показывает иконки оружия из HotbarComponent.

@onready var hbox: HBoxContainer = $HBoxContainer

var hotbar: HotbarComponent = null
var slots_ui: Array = []

func _ready() -> void:
	await get_tree().process_frame
	var player = get_tree().get_first_node_in_group("player")
	if player:
		hotbar = player.get_node_or_null("HotbarComponent")
		if hotbar:
			hotbar.slot_changed.connect(_on_slot_changed)
			print("[HotbarUI] Подключен к HotbarComponent, slot_count=", hotbar.slot_count)
	_build_ui()
	_refresh_all()

## Пересоздать UI-слоты (один раз при старте)
func _build_ui() -> void:
	# Очищаем предыдущие слоты, если были
	for c in hbox.get_children():
		c.queue_free()
	slots_ui.clear()

	for i in range(9):
		var slot := PanelContainer.new()
		slot.custom_minimum_size = Vector2(50, 50)

		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.15, 0.15, 0.2, 0.85)
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.border_color = Color(0.5, 0.5, 0.5, 1)
		slot.add_theme_stylebox_override("panel", style)

		var vbox := VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(vbox)

		var num := Label.new()
		num.text = str(i + 1)
		num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		num.add_theme_font_size_override("font_size", 10)
		num.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(num)

		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(32, 32)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(icon)

		hbox.add_child(slot)
		slots_ui.append({"panel": slot, "icon": icon})

	print("[HotbarUI] Построено ", slots_ui.size(), " слотов")

## Обновить ВСЕ слоты (на случай пропущенных сигналов)
func _refresh_all() -> void:
	if hotbar == null:
		return
	for i in range(slots_ui.size()):
		_update_slot_icon(i)

## Обновить один слот по индексу
func _update_slot_icon(index: int) -> void:
	if index < 0 or index >= slots_ui.size():
		return
	if hotbar == null:
		return
	var weapon = hotbar.get_slot(index)
	var icon: TextureRect = slots_ui[index]["icon"]
	if weapon and weapon.icon:
		icon.texture = weapon.icon
	else:
		icon.texture = null

## Сигнал от HotbarComponent: изменился слот
func _on_slot_changed(index: int) -> void:
	print("[HotbarUI] slot_changed index=", index, " | slots_ui.size=", slots_ui.size)
	_update_slot_icon(index)
