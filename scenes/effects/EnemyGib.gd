extends RigidBody3D

func apply_impulse_from_gib(impulse: Vector3) -> void:
	apply_central_impulse(impulse)
	angular_velocity = Vector3(
		randf_range(-8, 8),
		randf_range(-8, 8),
		randf_range(-8, 8)
	)

func _ready() -> void:
	await get_tree().create_timer(10.0).timeout
	queue_free()
