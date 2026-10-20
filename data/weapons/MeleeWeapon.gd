extends Weapon
class_name MeleeWeapon

## Мили-оружие: нож, топор, меч.

@export var attack_angle: float = 90.0

func use(player: Node) -> bool:
	var forward: Vector3 = -player.global_transform.basis.z
	forward.y = 0
	forward = forward.normalized()

	# Враги
	for enemy in player.get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(enemy):
			_hit_target(enemy, player, forward)

	# Разрушаемые объекты
	for target in player.get_tree().get_nodes_in_group("breakable"):
		if is_instance_valid(target):
			_hit_target(target, player, forward)

	return true

func _hit_target(target: Node, player: Node, forward: Vector3) -> void:
	var target_3d := target as Node3D
	if target_3d == null:
		return
	var to_target: Vector3 = target_3d.global_position - player.global_position
	to_target.y = 0
	var dist: float = to_target.length()
	if dist > range:
		return
	to_target = to_target.normalized()
	var angle_deg: float = rad_to_deg(forward.angle_to(to_target))
	if angle_deg > attack_angle / 2.0:
		return

	# Урон — враг через HealthComponent, breakable через take_damage
	if target.has_method("take_damage"):
		target.take_damage(damage)
		print("[Melee] Попал по ", target.name, " на ", damage)
	else:
		var eh = target.get_node_or_null("HealthComponent")
		if eh:
			eh.take_damage(damage)
			print("[Melee] Попал по ", target.name, " на ", damage)
