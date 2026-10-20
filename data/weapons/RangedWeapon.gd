extends Weapon
class_name RangedWeapon

## Ренж-оружие. Тратит патроны из магазина, перезаряжается.
## Патроны ищутся по ammo_type, не по id.

@export var projectile_speed: float = 30.0
@export var projectile_scene: PackedScene

func use(player: Node) -> bool:
	if projectile_scene == null:
		print("[Ranged] Нет сцены снаряда")
		return false

	# Проверка патронов
	if magazine_size > 0:
		if current_ammo <= 0:
			print("[Ranged] Магазин пуст — нажми R для перезарядки")
			return false
		current_ammo -= 1

	var projectile := projectile_scene.instantiate()
	var spawn_pos: Vector3 = player.global_position + Vector3.UP * 1.0
	var dir: Vector3 = -player.global_transform.basis.z
	dir.y = 0
	dir = dir.normalized()
	player.get_tree().current_scene.add_child(projectile)
	projectile.global_position = spawn_pos
	if projectile.has_method("setup"):
		projectile.setup(dir, projectile_speed, damage, player)

	print("[Ranged] Выстрел | патронов в магазине: ", current_ammo)
	return true

## Перезарядка. Ищет патроны по ammo_type.
func reload(player: Node) -> bool:
	if magazine_size <= 0:
		return false
	if ammo_type == "":
		print("[Ranged] ammo_type не задан")
		return false
	if current_ammo >= magazine_size:
		print("[Ranged] Магазин полон")
		return false

	var inv = player.get_node_or_null("InventoryComponent")
	if inv == null:
		return false

	var needed: int = magazine_size - current_ammo
	var have: int = inv.get_ammo_count(ammo_type)
	if have <= 0:
		print("[Ranged] Нет патронов типа ", ammo_type)
		return false

	var to_load: int = min(needed, have)
	var removed: int = inv.remove_ammo(ammo_type, to_load)
	current_ammo += removed
	print("[Ranged] Перезарядка: +", removed, " | в магазине: ", current_ammo, "/", magazine_size)
	return true
