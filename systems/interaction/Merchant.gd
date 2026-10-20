extends Interactable
class_name Merchant

## Торговец. F открывает UI магазина.

@onready var merchant_comp: MerchantComponent = get_node_or_null("MerchantComponent")

var ui_open: bool = false

func _ready() -> void:
	add_to_group("merchant")

func interact(player: Node) -> void:
	if ui_open:
		return
	ui_open = true
	print("[Merchant] Открыт: ", name)

	var ui_scene := load("res://scenes/ui/MerchantUI.tscn")
	if ui_scene == null:
		push_warning("[Merchant] Нет MerchantUI.tscn")
		ui_open = false
		return
	var ui = ui_scene.instantiate()
	get_tree().current_scene.add_child(ui)
	ui.open(self, player)

func close_ui() -> void:
	ui_open = false

func get_merchant() -> MerchantComponent:
	return merchant_comp
