extends Item
class_name Weapon

@export var damage: int = 10
@export var cooldown: float = 0.5
@export var range: float = 2.0
@export var is_ranged: bool = false
@export var model_scene: PackedScene

@export var ammo_type: String = ""
@export var magazine_size: int = 0

var current_ammo: int = 0

func use(player: Node) -> bool:
	return false
