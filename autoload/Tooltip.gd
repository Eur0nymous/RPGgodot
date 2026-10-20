extends CanvasLayer

## Глобальный тултип. Показывает имя, описание, характеристики предмета.
## Показ: Tooltip.show_item(item, position).

var panel: PanelContainer = null
var name_label: Label = null
var desc_label: Label = null
var stats_label: Label = null
var price_label: Label = null

func _ready() -> void:
	layer = 100
	_build_ui()
	hide_tooltip()

func _build_ui() -> void:
	panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(220, 0)

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12, 0.95)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.6, 0.5, 0.3, 1)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	name_label = Label.new()
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
	vbox.add_child(name_label)

	desc_label = Label.new()
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size = Vector2(200, 0)
	vbox.add_child(desc_label)

	stats_label = Label.new()
	stats_label.add_theme_font_size_override("font_size", 12)
	stats_label.add_theme_color_override("font_color", Color(0.7, 0.9, 0.7))
	vbox.add_child(stats_label)

	price_label = Label.new()
	price_label.add_theme_font_size_override("font_size", 12)
	price_label.add_theme_color_override("font_color", Color(1, 0.7, 0.3))
	vbox.add_child(price_label)

	add_child(panel)

func show_item(item: Item, pos: Vector2 = Vector2.ZERO) -> void:
	if item == null:
		hide_tooltip()
		return

	name_label.text = item.name
	desc_label.text = item.description if item.description != "" else ""

	var stats: String = ""
	if item is Weapon:
		var w: Weapon = item as Weapon
		stats += "Урон: " + str(w.damage) + "\n"
		stats += "Кулдаун: " + str(w.cooldown) + " сек\n"
		if w is RangedWeapon:
			var rw: RangedWeapon = w as RangedWeapon
			if rw.magazine_size > 0:
				stats += "Магазин: " + str(rw.magazine_size) + "\n"
				stats += "Патроны: " + rw.ammo_type + "\n"
	elif item is Armor:
		var a: Armor = item as Armor
		stats += "Защита: " + str(a.armor_value) + "\n"
	elif item is Helmet:
		var h: Helmet = item as Helmet
		stats += "Защита: " + str(h.armor_value) + "\n"
	elif item is Ammo:
		var am: Ammo = item as Ammo
		stats += "Тип: " + am.ammo_type + "\n"
	stats_label.text = stats.strip_edges()

	price_label.text = "Цена: " + str(item.price) + " ₽"

	panel.position = _clamp_position(pos)
	panel.visible = true

func hide_tooltip() -> void:
	if panel:
		panel.visible = false

func _clamp_position(pos: Vector2) -> Vector2:
	var viewport: Vector2 = get_viewport().get_visible_rect().size
	var size: Vector2 = panel.size
	if size.x == 0:
		size = Vector2(220, 150)
	var x: float = clamp(pos.x, 0, viewport.x - size.x)
	var y: float = clamp(pos.y, 0, viewport.y - size.y)
	return Vector2(x, y)
