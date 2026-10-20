extends Resource
class_name Item

@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var icon: Texture2D
@export var world_model_scene: PackedScene
@export var stackable: bool = false
@export var max_stack: int = 1
@export var price: int = 10   # ← базовая цена
