extends CanvasLayer

@onready var new_game_button: Button = $VBoxContainer/NewGameButton
@onready var load_button: Button = $VBoxContainer/LoadButton
@onready var quit_button: Button = $VBoxContainer/QuitButton

func _ready() -> void:
	new_game_button.pressed.connect(_on_new_game)
	load_button.pressed.connect(_on_load)
	quit_button.pressed.connect(_on_quit)

func _on_new_game() -> void:
	# Сброс флагов — новая игра
	FlagManager.clear_all()
	# Загружаем TestLevel (потом будет Пролог)
	get_tree().change_scene_to_file("res://scenes/levels/TestLevel.tscn")

func _on_load() -> void:
	if SaveSystem.load_game(0):
		get_tree().change_scene_to_file("res://scenes/levels/TestLevel.tscn")

func _on_quit() -> void:
	get_tree().quit()
