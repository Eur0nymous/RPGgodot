extends RigidBody3D

## Обломок дерева. Небольшой разлёт при спавне. Самоуничтожается через 10 сек.

func _ready() -> void:
	var impulse := Vector3(
		randf_range(-1, 1),
		randf_range(0.3, 0.8),
		randf_range(-1, 1)
	).normalized() * randf_range(0.5, 1.2)
	apply_central_impulse(impulse)
	angular_velocity = Vector3(
		randf_range(-3, 3),
		randf_range(-3, 3),
		randf_range(-3, 3)
	)
	await get_tree().create_timer(10.0).timeout
	queue_free()
