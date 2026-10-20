extends Node
class_name BreakableComponent

## HP разрушаемого объекта.
## Когда HP = 0 — сигнал died.

signal damaged(amount: int, current: int, max_hp: int)
signal died

@export var max_health: int = 30
@export var armor: int = 0

var current_health: int

func _ready() -> void:
	current_health = max_health

func take_damage(amount: int) -> void:
	if amount <= 0:
		return
	if current_health <= 0:
		return
	var actual: int = max(1, amount - armor)
	current_health = max(0, current_health - actual)
	damaged.emit(actual, current_health, max_health)
	if current_health == 0:
		died.emit()

func is_alive() -> bool:
	return current_health > 0

func to_dict() -> Dictionary:
	return {"current": current_health, "max": max_health}

func from_dict(data: Dictionary) -> void:
	current_health = data.get("current", max_health)
