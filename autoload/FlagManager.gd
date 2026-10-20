extends Node

## Хранит флаги мира: выборы игрока, состояния квестов.
## Ключ-значение. Сохраняется в SaveSystem.

signal flag_changed(flag_name: String, value: Variant)

var flags: Dictionary = {}

func _ready() -> void:
	print("[FlagManager] Ready")

func set_flag(flag_name: String, value: Variant = true) -> void:
	flags[flag_name] = value
	flag_changed.emit(flag_name, value)

func get_flag(flag_name: String, default: Variant = false) -> Variant:
	return flags.get(flag_name, default)

func has_flag(flag_name: String) -> bool:
	return flags.has(flag_name)

func clear_flag(flag_name: String) -> void:
	flags.erase(flag_name)

func clear_all() -> void:
	flags.clear()

func to_dict() -> Dictionary:
	return flags.duplicate()

func from_dict(data: Dictionary) -> void:
	flags = data.duplicate()
