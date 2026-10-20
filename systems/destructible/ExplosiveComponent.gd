extends Node
class_name ExplosiveComponent

## Компонент взрыва. При активации наносит урон всем в радиусе.

signal exploded(position: Vector3)

@export var damage: int = 50
@export var radius: float = 4.0
@export var knockback_force: float = 12.0
@export var explosion_effect_scene: PackedScene
@export var chain_explosion_delay: float = 0.15

var has_exploded: bool = false

func explode(source_position: Vector3) -> void:
	if has_exploded:
		return
	has_exploded = true

	print("[Explosive] Взрыв в ", source_position, " | урон ", damage, " | радиус ", radius)

	# 1. Эффект
	if explosion_effect_scene:
		var effect = explosion_effect_scene.instantiate()
		effect.position = source_position
		get_tree().current_scene.add_child(effect)
		effect.global_position = source_position
		print("[Explosion] Эффект на позиции ", effect.global_position)
	else:
		print("[Explosive] Нет explosion_effect_scene")

	# 2. Урон всем в радиусе
	_apply_damage(source_position)

	exploded.emit(source_position)

func _apply_damage(source_position: Vector3) -> void:
	var space := get_tree().root.world_3d.direct_space_state
	var query := PhysicsShapeQueryParameters3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = radius
	query.shape = sphere
	query.transform = Transform3D(Basis(), source_position)
	query.collide_with_areas = true
	query.collide_with_bodies = true

	var results := space.intersect_shape(query, 32)
	var hit_nodes: Array = []
	var parent = get_parent()

	for result in results:
		var collider = result.collider
		if collider == null:
			continue
		if collider in hit_nodes:
			continue
		hit_nodes.append(collider)
		if collider == parent:
			continue

		# HealthComponent — враг / игрок
		var health = collider.get_node_or_null("HealthComponent")
		if health:
			var dist: float = source_position.distance_to(collider.global_position)
			var falloff: float = clamp(1.0 - (dist / radius), 0.2, 1.0)
			var dmg: int = int(damage * falloff)
			health.take_damage(dmg)
			print("[Explosive] Урон ", dmg, " по ", collider.name)
			if collider is RigidBody3D:
				var dir: Vector3 = collider.global_position - source_position
				dir.y = 0.3
				dir = dir.normalized()
				collider.apply_central_impulse(dir * knockback_force)
			continue

		# Breakable — через take_damage
		if collider.has_method("take_damage"):
			var dist2: float = source_position.distance_to(collider.global_position)
			var falloff2: float = clamp(1.0 - (dist2 / radius), 0.2, 1.0)
			var dmg2: int = int(damage * falloff2)
			collider.take_damage(dmg2)
			print("[Explosive] Урон ", dmg2, " по breakable ", collider.name)

		# Другая взрывчатка — цепная реакция
		var other_explosive = collider.get_node_or_null("ExplosiveComponent")
		if other_explosive and not other_explosive.has_exploded:
			_chain_explode(other_explosive)

func _chain_explode(other: ExplosiveComponent) -> void:
	if other == null:
		return
	if other.has_exploded:
		return
	await get_tree().create_timer(chain_explosion_delay).timeout
	if is_instance_valid(other) and not other.has_exploded:
		var pos = other.get_parent().global_position
		print("[Explosive] Цепная реакция → ", other.get_parent().name)
		other.explode(pos)
