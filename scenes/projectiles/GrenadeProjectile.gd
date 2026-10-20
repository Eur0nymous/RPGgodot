extends RigidBody3D

## Летящая граната. Взрывается через fuse_time.

@export var fuse_time: float = 2.0

var _exploded: bool = false

func _ready() -> void:
	await get_tree().create_timer(fuse_time).timeout
	_explode()

func _explode() -> void:
	if _exploded:
		return
	_exploded = true
	var explosive = get_node_or_null("ExplosiveComponent")
	if explosive:
		explosive.explode(global_position)
	queue_free()
