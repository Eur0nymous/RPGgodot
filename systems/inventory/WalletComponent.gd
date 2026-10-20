extends Node
class_name WalletComponent

## Деньги игрока.

signal money_changed(amount: int)

@export var starting_money: int = 100

var money: int = 0

func _ready() -> void:
	money = starting_money

func add(amount: int) -> void:
	if amount <= 0:
		return
	money += amount
	money_changed.emit(money)
	print("[Wallet] +", amount, " | всего: ", money)

func can_afford(amount: int) -> bool:
	return money >= amount

func spend(amount: int) -> bool:
	if amount <= 0:
		return false
	if money < amount:
		return false
	money -= amount
	money_changed.emit(money)
	print("[Wallet] -", amount, " | всего: ", money)
	return true

func to_dict() -> Dictionary:
	return {"money": money}

func from_dict(data: Dictionary) -> void:
	money = int(data.get("money", starting_money))
	money_changed.emit(money)
