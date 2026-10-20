extends RigidBody3D
class_name PickupItem

## Физический предмет в мире.
## Поддержка нескольких мешей: коллизия по всем вершинам (ConvexPolygonShape3D).
## Рекурсивная подсветка всех мешей.

@export var item: Item
@export var amount: int = 1
@export var prompt: String = "Подобрать"
@export var enabled: bool = true

@onready var mesh_placeholder: MeshInstance3D = get_node_or_null("MeshInstance3D")
@onready var collision_shape: CollisionShape3D = get_node_or_null("CollisionShape3D")

var _spawned_model: Node3D = null
var _highlight_material: StandardMaterial3D = null
# Оригинальные материалы по каждому мешу
var _original_materials: Dictionary = {}

func _ready() -> void:
	add_to_group("pickup")

	# Спавн модели, если задана
	if item and item.world_model_scene:
		_spawned_model = item.world_model_scene.instantiate()
		add_child(_spawned_model)
		if mesh_placeholder:
			mesh_placeholder.visible = false
		_fit_collision_to_mesh(_spawned_model)
	else:
		# Если модели нет — оставляем куб-заглушку
		if mesh_placeholder:
			_fit_collision_to_mesh(mesh_placeholder)

func _find_first_mesh(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	for child in node.get_children():
		var found := _find_first_mesh(child)
		if found:
			return found
	return null

## Рекурсивно собирает ВСЕ вершины со всех MeshInstance3D в node,
## с учётом трансформа каждого меша относительно root.
func _collect_all_vertices(node: Node, root: Node3D, out: PackedVector3Array) -> void:
	if node is MeshInstance3D and node.mesh:
		var verts: PackedVector3Array = node.mesh.get_faces()

		# Трансформ меша относительно root
		var transform_to_root: Transform3D
		if node == root:
			transform_to_root = Transform3D.IDENTITY
		else:
			transform_to_root = root.global_transform.affine_inverse() * node.global_transform

		for v in verts:
			out.append(transform_to_root * v)

	for child in node.get_children():
		_collect_all_vertices(child, root, out)

func _fit_collision_to_mesh(node: Node3D) -> void:
	if collision_shape == null:
		return

	# Собираем вершины со ВСЕХ мешей
	var all_vertices := PackedVector3Array()
	_collect_all_vertices(node, node, all_vertices)

	if all_vertices.is_empty():
		push_warning("[PickupItem] Модель без вершин, оставляем Box")
		var first_mesh := _find_first_mesh(node)
		if first_mesh:
			var aabb: AABB = first_mesh.get_aabb()
			var box := BoxShape3D.new()
			box.size = aabb.size
			collision_shape.shape = box
			collision_shape.position = aabb.get_center()
		return

	if all_vertices.size() < 4:
		push_warning("[PickupItem] Мало вершин для convex, fallback на Box")
		var first_mesh := _find_first_mesh(node)
		if first_mesh:
			var aabb: AABB = first_mesh.get_aabb()
			var box := BoxShape3D.new()
			box.size = aabb.size
			collision_shape.shape = box
			collision_shape.position = aabb.get_center()
		return

	var convex := ConvexPolygonShape3D.new()
	convex.points = all_vertices
	collision_shape.shape = convex
	collision_shape.position = Vector3.ZERO
	collision_shape.rotation = Vector3.ZERO

	print("[PickupItem] Convex shape: ", all_vertices.size(), " vertices")

func interact(player: Node) -> void:
	if not enabled:
		return
	if item == null:
		return
	# Снимаем подсветку перед удалением
	hide_highlight()
	var inv = player.get_node_or_null("InventoryComponent")
	if inv:
		if inv.add_item(item, amount):
			print("[Pickup] Получено: ", item.name, " x", amount)
			queue_free()

func get_prompt() -> String:
	return prompt

# --- Подсветка ---

func _ensure_highlight_material() -> void:
	if _highlight_material != null:
		return
	# Создаём базовый материал с эмиссией
	_highlight_material = StandardMaterial3D.new()
	_highlight_material.albedo_color = Color(0.8, 0.7, 0.3)
	_highlight_material.emission_enabled = true
	_highlight_material.emission = Color(1, 0.8, 0.2)
	_highlight_material.emission_energy_multiplier = 2.0

func show_highlight() -> void:
	_ensure_highlight_material()
	if _spawned_model:
		_apply_highlight_recursive(_spawned_model, true)
	elif mesh_placeholder:
		_apply_highlight_recursive(mesh_placeholder, true)

func hide_highlight() -> void:
	if _spawned_model:
		_apply_highlight_recursive(_spawned_model, false)
	elif mesh_placeholder:
		_apply_highlight_recursive(mesh_placeholder, false)

func _apply_highlight_recursive(node: Node, on: bool) -> void:
	if node is MeshInstance3D:
		var id := node.get_instance_id()
		if on:
			# Если ещё НЕ запоминали — запоминаем ТЕКУЩИЙ (оригинал)
			if not _original_materials.has(id):
				_original_materials[id] = node.material_override
			node.material_override = _highlight_material
		else:
			if _original_materials.has(id):
				node.material_override = _original_materials[id]
				_original_materials.erase(id)
			else:
				# Если не запоминали — сбрасываем на null
				node.material_override = null
	for child in node.get_children():
		_apply_highlight_recursive(child, on)
