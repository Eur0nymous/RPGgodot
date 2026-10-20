extends Node

## База всех предметов: id → Item.
## Сканирует папки при старте.

var items: Dictionary = {}  # id → Item

func _ready() -> void:
	print("[ItemDatabase] Ready")
	_scan_folder("res://data/items/")
	_scan_folder("res://data/weapons/")
	_scan_folder("res://data/equipment/")
	print("[ItemDatabase] Загружено: ", items.size(), " предметов")

func _scan_folder(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if dir.current_is_dir():
			if file_name != "." and file_name != "..":
				_scan_folder(path + file_name + "/")
		elif file_name.ends_with(".tres"):
			var res: Resource = load(path + file_name)
			if res is Item and res.id != "":
				items[res.id] = res
		file_name = dir.get_next()
	dir.list_dir_end()

func get_item(item_id: String) -> Item:
	return items.get(item_id, null)

func has_item(item_id: String) -> bool:
	return items.has(item_id)
