extends Node
class_name GibsComponent

## Спавнит куски тела при смерти.

signal gibbed

@export var gibs_scene: PackedScene
@export var gibs_impulse: float = 1.5   # было 4.0
@export var gibs_count: int = 5         # было 6
@export var blood_effect_scene: PackedScene   # опционально

func gib(source_position: Vector3, forward: Vector3 = Vector3.ZERO) -> void:
	if gibs_scene == null:
		push_warning("[Gibs] Нет gibs_scene у ", get_parent().name)
		return

	for i in range(gibs_count):
		var gib = gibs_scene.instantiate()
		get_tree().current_scene.add_child(gib)
		gib.global_position = source_position + Vector3(
			randf_range(-0.2, 0.2),
			randf_range(0.0, 0.5),
			randf_range(-0.2, 0.2)
		)
		# Мягкий импульс — только в стороны, чуть вверх
		var rand_dir := Vector3(
			randf_range(-1, 1),
			randf_range(0.3, 0.8),
			randf_range(-1, 1)
		).normalized()
		var impulse := rand_dir * gibs_impulse
		if forward.length() > 0.1:
			impulse += forward.normalized() * gibs_impulse * 0.3
		if gib.has_method("apply_impulse_from_gib"):
			gib.apply_impulse_from_gib(impulse)
		elif gib is RigidBody3D:
			gib.apply_central_impulse(impulse)

	if blood_effect_scene:
		var effect = blood_effect_scene.instantiate()
		get_tree().current_scene.add_child(effect)
		effect.global_position = source_position

	gibbed.emit()

	# Эффект крови / искр
	if blood_effect_scene:
		var effect = blood_effect_scene.instantiate()
		get_tree().current_scene.add_child(effect)
		effect.global_position = source_position

	gibbed.emit()
