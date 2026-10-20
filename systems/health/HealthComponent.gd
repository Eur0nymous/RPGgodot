extends Node
class_name HealthComponent

## Компонент здоровья. Добавляется к игроку, врагу, NPC.

signal damaged(amount: int, current: int, max: int)
signal healed(amount: int, current: int, max: int)
signal died

@export var max_health: int = 100

var current_health: int

func _ready() -> void:
	current_health = max_health

@export var armor: int = 0

func take_damage(amount: int) -> void:
	if amount <= 0:
		return
	var actual: int = max(1, amount - armor)
	current_health = max(0, current_health - actual)
	damaged.emit(actual, current_health, max_health)
	if current_health == 0:
		died.emit()

func heal(amount: int) -> void:
	if amount <= 0:
		return
	current_health = min(max_health, current_health + amount)
	healed.emit(amount, current_health, max_health)

func is_alive() -> bool:
	return current_health > 0

func get_health_percent() -> float:
	return float(current_health) / float(max_health)

func to_dict() -> Dictionary:
	return {"current": current_health, "max": max_health}

func from_dict(data: Dictionary) -> void:
	current_health = data.get("current", max_health)
	max_health = data.get("max", max_health)
