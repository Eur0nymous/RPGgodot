extends Node

signal game_paused(is_paused: bool)
signal scene_changed(scene_path: String)

var is_paused: bool = false
var current_scene_path: String = ""

func _ready() -> void:
	print("[GameManager] Ready")

func pause_game() -> void:
	is_paused = true
	get_tree().paused = true
	game_paused.emit(true)

func resume_game() -> void:
	is_paused = false
	get_tree().paused = false
	game_paused.emit(false)

func toggle_pause() -> void:
	if is_paused:
		resume_game()
	else:
		pause_game()

func change_scene(scene_path: String) -> void:
	current_scene_path = scene_path
	get_tree().change_scene_to_file(scene_path)
	scene_changed.emit(scene_path)
