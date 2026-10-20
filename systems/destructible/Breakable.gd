extends RigidBody3D
class_name Breakable

## Разрушаемый физический объект (ящик, бочка).
## Падает, толкается, ломается при HP=0.
## Опционально — взрывается (бочки, газовые баллоны).

signal broken

## Loot
@export var loot_item: Item
@export var loot_amount: int = 1
@export var loot_chance: float = 1.0

## Effects
@export var impact_effect_scene: PackedScene
@export var debris_scene: PackedScene
@export var debris_count: int = 6
@export var break_effect_scene: PackedScene

## Explosive (0 = не взрывчатка)
@export var explosive_damage: int = 0
@export var explosive_radius: float = 4.0
@export var explosive_effect_scene: PackedScene
@export var chain_explosion_delay: float = 0.15

@onready var breakable: BreakableComponent = get_node_or_null("BreakableComponent")
@onready var mesh: MeshInstance3D = get_node_or_null("MeshInstance3D")

func _ready() -> void:
	add_to_group("breakable")
	if breakable == null:
		push_warning("[Breakable] Нет BreakableComponent: ", name)
		return
	breakable.died.connect(_on_died)
	breakable.damaged.connect(_on_damaged)

func take_damage(amount: int) -> void:
	if breakable == null:
		return
	breakable.take_damage(amount)

func _on_damaged(amount: int, current: int, max_hp: int) -> void:
	var hit_point := _get_random_hit_point()
	_spawn_impact_effect(hit_point)
	print("[Breakable] ", name, " HP: ", current, "/", max_hp, " (урон ", amount, ")")

func _on_died() -> void:
	print("[Breakable] Разрушен: ", name)
	broken.emit()
	_spawn_break_effect()
	_spawn_debris()
	_spawn_loot()

	if explosive_damage > 0:
		_trigger_explosion()

	queue_free()

## --- Точка удара ---

func _get_random_hit_point() -> Vector3:
	if mesh == null:
		return global_position + Vector3.UP * 0.6

	var aabb := mesh.get_aabb()
	var size := aabb.size * 0.5
	var side := randi() % 6
	var pos := Vector3.ZERO

	match side:
		0: pos = Vector3(size.x + 0.05, randf_range(-size.y, size.y), randf_range(-size.z, size.z))
		1: pos = Vector3(-size.x - 0.05, randf_range(-size.y, size.y), randf_range(-size.z, size.z))
		2: pos = Vector3(randf_range(-size.x, size.x), randf_range(-size.y, size.y), size.z + 0.05)
		3: pos = Vector3(randf_range(-size.x, size.x), randf_range(-size.y, size.y), -size.z - 0.05)
		4: pos = Vector3(randf_range(-size.x, size.x), size.y + 0.05, randf_range(-size.z, size.z))
		5: pos = Vector3(randf_range(-size.x, size.x), -size.y - 0.05, randf_range(-size.z, size.z))

	return global_position + pos

## --- Эффекты ---

func _spawn_impact_effect(pos: Vector3) -> void:
	if impact_effect_scene == null:
		return
	var effect = impact_effect_scene.instantiate()
	get_tree().current_scene.add_child(effect)
	effect.global_position = pos

func _spawn_break_effect() -> void:
	if break_effect_scene == null:
		return
	var effect = break_effect_scene.instantiate()
	get_tree().current_scene.add_child(effect)
	effect.global_position = global_position

## --- Обломки ---

func _spawn_debris() -> void:
	if debris_scene == null:
		return
	for i in range(debris_count):
		var debris = debris_scene.instantiate()
		get_tree().current_scene.add_child(debris)
		var offset := Vector3(
			randf_range(-0.15, 0.15),
			randf_range(0.0, 0.3),
			randf_range(-0.15, 0.15)
		)
		debris.global_position = global_position + offset

## --- Лут ---

func _spawn_loot() -> void:
	if loot_item == null:
		return
	if randf() > loot_chance:
		return
	var pickup_scene := load("res://systems/interaction/PickupItem.tscn")
	if pickup_scene == null:
		return
	var pickup = pickup_scene.instantiate()
	pickup.item = loot_item
	pickup.amount = loot_amount
	get_tree().current_scene.add_child(pickup)
	pickup.global_position = global_position + Vector3.UP * 0.5
	print("[Breakable] Выпал лут: ", loot_item.name, " x", loot_amount)

## --- Взрыв ---

func _trigger_explosion() -> void:
	var explosive: ExplosiveComponent = get_node_or_null("ExplosiveComponent")
	if explosive == null:
		explosive = ExplosiveComponent.new()
		explosive.name = "ExplosiveComponent"
		add_child(explosive)

	explosive.damage = explosive_damage
	explosive.radius = explosive_radius
	explosive.chain_explosion_delay = chain_explosion_delay

	if explosive_effect_scene:
		explosive.explosion_effect_scene = explosive_effect_scene
	else:
		var default_effect = load("res://scenes/effects/ExplosionEffect.tscn")
		if default_effect:
			explosive.explosion_effect_scene = default_effect

	explosive.explode(global_position)
