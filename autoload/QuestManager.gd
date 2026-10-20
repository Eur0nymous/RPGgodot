extends Node

signal quest_started(quest: Quest)
signal quest_ready_to_turn_in(quest: Quest)
signal quest_completed(quest: Quest)

var active_quests: Array[Quest] = []
var ready_quests: Array[Quest] = []
var completed_quests: Array[Quest] = []

func _ready() -> void:
	print("[QuestManager] Ready")
	FlagManager.flag_changed.connect(_on_flag_changed)

func start_quest(quest: Quest) -> void:
	if quest == null:
		return
	if quest in active_quests or quest in ready_quests or quest in completed_quests:
		return
	active_quests.append(quest)
	quest_started.emit(quest)
	print("[QuestManager] Начат квест: ", quest.title)

func start_quest_by_id(quest_id: String) -> void:
	var path := "res://data/quests/" + quest_id + ".tres"
	if ResourceLoader.exists(path):
		var quest: Quest = load(path)
		start_quest(quest)
	else:
		push_warning("[QuestManager] Нет квеста: " + path)

func complete_quest(quest: Quest) -> void:
	if quest == null:
		return
	if not (quest in ready_quests):
		print("[QuestManager] Квест не готов к сдаче: ", quest.title)
		return

	ready_quests.erase(quest)
	completed_quests.append(quest)
	quest_completed.emit(quest)
	print("[QuestManager] Завершён квест: ", quest.title)

	if quest.reward_item:
		var player = get_tree().get_first_node_in_group("player")
		if player:
			var inv = player.get_node_or_null("InventoryComponent")
			if inv:
				inv.add_item(quest.reward_item, quest.reward_amount)
				print("[QuestManager] Награда: ", quest.reward_item.name, " x", quest.reward_amount)

func complete_quest_by_id(quest_id: String) -> void:
	var path := "res://data/quests/" + quest_id + ".tres"
	if ResourceLoader.exists(path):
		var quest: Quest = load(path)
		complete_quest(quest)

func _on_flag_changed(flag_name: String, _value: Variant) -> void:
	for quest in active_quests.duplicate():
		if quest.is_complete_check(flag_name):
			active_quests.erase(quest)
			ready_quests.append(quest)
			quest_ready_to_turn_in.emit(quest)
			print("[QuestManager] Квест готов к сдаче: ", quest.title)

func is_ready_to_turn_in(quest_id: String) -> bool:
	for q in ready_quests:
		if q.id == quest_id:
			return true
	return false

func is_completed(quest_id: String) -> bool:
	for q in completed_quests:
		if q.id == quest_id:
			return true
	return false

func is_active(quest_id: String) -> bool:
	for q in active_quests:
		if q.id == quest_id:
			return true
	return false

func to_dict() -> Dictionary:
	var data := {"active": [], "ready": [], "completed": []}
	for q in active_quests: data["active"].append(q.id)
	for q in ready_quests: data["ready"].append(q.id)
	for q in completed_quests: data["completed"].append(q.id)
	return data

func from_dict(data: Dictionary) -> void:
	active_quests.clear()
	ready_quests.clear()
	completed_quests.clear()

	for id in data.get("active", []):
		var q = load("res://data/quests/" + id + ".tres")
		if q: active_quests.append(q)
	for id in data.get("ready", []):
		var q = load("res://data/quests/" + id + ".tres")
		if q: ready_quests.append(q)
	for id in data.get("completed", []):
		var q = load("res://data/quests/" + id + ".tres")
		if q: completed_quests.append(q)

	print("[QuestManager] Loaded: ", active_quests.size(), " active, ", ready_quests.size(), " ready, ", completed_quests.size(), " completed")
