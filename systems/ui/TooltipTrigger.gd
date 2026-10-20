extends Control
class_name TooltipTrigger

## Показывает тултип при наведении. Не перехватывает клики.

var _item: Item = null
var _show_timer: float = 0.0
var _hovering: bool = false

const DELAY: float = 0.4

func setup(item: Item) -> void:
	_item = item

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	mouse_entered.connect(_on_enter)
	mouse_exited.connect(_on_exit)

func _on_enter() -> void:
	_hovering = true
	_show_timer = DELAY

func _on_exit() -> void:
	_hovering = false
	Tooltip.hide_tooltip()

func _process(delta: float) -> void:
	if not _hovering:
		return
	if _show_timer > 0:
		_show_timer -= delta
		if _show_timer <= 0:
			_show_tooltip()

func _show_tooltip() -> void:
	if _item == null:
		return
	Tooltip.show_item(_item, get_global_mouse_position())
