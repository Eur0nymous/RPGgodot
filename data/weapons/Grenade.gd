extends Weapon
class_name Grenade

## Граната. Тратит current_ammo, при 0 удаляется из хотбара.

@export var grenade_projectile_scene: PackedScene
@export var throw_force: float = 12.0

func use(player: Node) -> bool:
	if grenade_projectile_scene == null:
		print("[Grenade] Нет grenade_projectile_scene")
		return false
	if current_ammo <= 0:
		print("[Grenade] Гранат нет")
		return false

	var grenade = grenade_projectile_scene.instantiate()
	var forward: Vector3 = -player.global_transform.basis.z
	forward.y = 0
	forward = forward.normalized()
	var spawn_pos: Vector3 = player.global_position + forward * 0.6 + Vector3.UP * 1.2
	grenade.position = spawn_pos
	player.get_tree().current_scene.add_child(grenade)
	grenade.global_position = spawn_pos
	var throw_dir: Vector3 = (forward + Vector3.UP * 0.5).normalized()
	grenade.apply_central_impulse(throw_dir * throw_force)

	current_ammo -= 1
	print("[Grenade] Бросок | осталось: ", current_ammo)
	return true
