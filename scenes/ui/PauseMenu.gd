extends CanvasLayer

@onready var resume_button: Button = $VBoxContainer/ResumeButton
@onready var save_button: Button = $VBoxContainer/SaveButton
@onready var load_button: Button = $VBoxContainer/LoadButton
@onready var quit_button: Button = $VBoxContainer/QuitButton

func _ready() -> void:
	visible = false
	resume_button.pressed.connect(_on_resume)
	save_button.pressed.connect(_on_save)
	load_button.pressed.connect(_on_load)
	quit_button.pressed.connect(_on_quit)
	GameManager.game_paused.connect(_on_game_paused)

func _on_game_paused(is_paused: bool) -> void:
	visible = is_paused

func _on_resume() -> void:
	GameManager.resume_game()

func _on_save() -> void:
	SaveSystem.save_game(0)

func _on_load() -> void:
	SaveSystem.load_game(0)

func _on_quit() -> void:
	get_tree().quit()
