extends CharacterBody3D

## Игрок. F — взаимодействие. F закрывает сундук.
## Хотбар 1-9, G — сброс оружия. Гранаты, патроны.

signal weapon_equipped(weapon: Weapon)
signal armor_equipped(item: Item)
signal helmet_equipped(item: Item)

@export var walk_speed: float = 5.0
@export var run_speed: float = 8.0
@export var acceleration: float = 6.0
@export var gravity: float = 20.0
@export var rotation_speed: float = 10.0
@export var push_strength: float = 15.0

@export var equipped_weapon: Weapon = null
@export var equipped_armor: Armor = null
@export var equipped_helmet: Helmet = null

@onready var camera: Camera3D = get_viewport().get_camera_3d()
@onready var raycast: RayCast3D = $RayCast3D
@onready var hud: CanvasLayer = get_tree().current_scene.get_node_or_null("HUD")
@onready var health: HealthComponent = $HealthComponent

# Путь к WeaponMount
@onready var weapon_mount: Node3D = get_node_or_null("model/Armature/Skeleton3D/BoneAttachment3D/WeaponMount")

@onready var armor_mount: Node3D = get_node_or_null("ArmorMount")
@onready var helmet_mount: Node3D = get_node_or_null("HelmetMount")
@onready var pickup_area: Area3D = $PickupArea
@onready var push_area: Area3D = get_node_or_null("PushArea")
@onready var inventory: InventoryComponent = get_node_or_null("InventoryComponent")
@onready var hotbar: HotbarComponent = get_node_or_null("HotbarComponent")

# --- ССЫЛКИ НА АНИМАЦИИ ---
@onready var anim_tree: AnimationTree = $AnimationTree

var current_interactable: Interactable = null
var attack_timer: float = 0.0
var current_weapon_model: Node3D = null
var current_armor_model: Node3D = null
var current_helmet_model: Node3D = null

var nearby_pickups: Array = []
var current_pickup: Node = null

var is_aiming: bool = false 

func _ready() -> void:
	add_to_group("player")
	health.died.connect(_on_died)
	health.damaged.connect(_on_damaged)

	pickup_area.body_entered.connect(_on_pickup_area_entered)
	pickup_area.body_exited.connect(_on_pickup_area_exited)

	if inventory:
		inventory.inventory_changed.connect(_on_inventory_changed)

	if equipped_weapon:
		equip_weapon(equipped_weapon)
	if equipped_armor:
		equip_armor(equipped_armor)
	if equipped_helmet:
		equip_helmet(equipped_helmet)

	if anim_tree:
		anim_tree.active = true

func _physics_process(delta: float) -> void:
	if attack_timer > 0:
		attack_timer -= delta

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")

	var direction := Vector3.ZERO
	if camera:
		var forward := -(global_position - camera.global_position)
		forward.y = 0
		forward = forward.normalized()
		var right := -(forward.cross(Vector3.UP).normalized())
		direction = (right * input_dir.x + forward * input_dir.y).normalized()
	else:
		direction = Vector3(input_dir.x, 0, input_dir.y).normalized()

	var target_speed := run_speed if Input.is_action_pressed("run") else walk_speed

	if direction.length() > 0.1:
		velocity.x = move_toward(velocity.x, direction.x * target_speed, acceleration)
		velocity.z = move_toward(velocity.z, direction.z * target_speed, acceleration)
	else:
		velocity.x = move_toward(velocity.x, 0, acceleration)
		velocity.z = move_toward(velocity.z, 0, acceleration)

	move_and_slide()

	_update_animations(direction, delta)
	_push_rigidbodies(delta)
	_update_interaction()
	_update_pickup_ui()
	_rotate_to_mouse(delta)

# --- ЛОГИКА АНИМАЦИЙ ---
func _update_animations(direction: Vector3, delta: float) -> void:
	if anim_tree == null:
		return

	# 1. Обычное движение (IdleOrMove)
	var target_move_amt = 1.0 if direction.length() > 0.1 else 0.0
	var current_move_amt = anim_tree.get("parameters/IdleOrMove/blend_amount")
	if current_move_amt == null: current_move_amt = 0.0
	anim_tree.set("parameters/IdleOrMove/blend_amount", lerp(current_move_amt, target_move_amt, delta * 6.0))

	# 2. Направление в BlendSpace2D (Обновляем и Movement, и Movement_Fix)
	if direction.length() > 0.1:
		var local_dir = direction.rotated(Vector3.UP, -rotation.y)
		var speed_mult = 2.0 if Input.is_action_pressed("run") else 1.0 
		var target_blend_pos = Vector2(local_dir.x * speed_mult, -local_dir.z * speed_mult)
		
		# Основной Movement
		var current_blend_pos = anim_tree.get("parameters/Movement/blend_position")
		if current_blend_pos == null: current_blend_pos = Vector2.ZERO
		if current_blend_pos.distance_to(target_blend_pos) < 0.05:
			anim_tree.set("parameters/Movement/blend_position", target_blend_pos)
		else:
			anim_tree.set("parameters/Movement/blend_position", current_blend_pos.lerp(target_blend_pos, delta * 10.0))
			
		# Movement_Fix (для ног с оружием)
		var current_blend_pos_fix = anim_tree.get("parameters/Movement_Fix/blend_position")
		if current_blend_pos_fix == null: current_blend_pos_fix = Vector2.ZERO
		if current_blend_pos_fix.distance_to(target_blend_pos) < 0.05:
			anim_tree.set("parameters/Movement_Fix/blend_position", target_blend_pos)
		else:
			anim_tree.set("parameters/Movement_Fix/blend_position", current_blend_pos_fix.lerp(target_blend_pos, delta * 10.0))

	# 3. Включаем оружие (UpperBodyBlend)
	var target_upper = 1.0 if is_aiming else 0.0
	var current_upper = anim_tree.get("parameters/UpperBodyBlend/blend_amount")
	if current_upper == null: current_upper = 0.0
	anim_tree.set("parameters/UpperBodyBlend/blend_amount", lerp(current_upper, target_upper, delta * 10.0))

	# 4. Фиксация рук в стойке (AimMovement)
	if is_aiming:
		var target_aim_pos = 0.0 
		var current_aim_pos = anim_tree.get("parameters/AimMovement/blend_position")
		if current_aim_pos == null: current_aim_pos = 0.0
		anim_tree.set("parameters/AimMovement/blend_position", lerp(current_aim_pos, target_aim_pos, delta * 10.0))

	# 5. ФИКС НОГ (LegsFixBlend)
	var target_legs_fix = 1.0 if is_aiming else 0.0
	var current_legs_fix = anim_tree.get("parameters/LegsFixBlend/blend_amount")
	if current_legs_fix == null: current_legs_fix = 0.0
	anim_tree.set("parameters/LegsFixBlend/blend_amount", lerp(current_legs_fix, target_legs_fix, delta * 10.0))
# --------------------------

func _try_attack() -> void:
	if attack_timer > 0: return
	if equipped_weapon == null:
		print("[Player] Нет оружия")
		return

	attack_timer = equipped_weapon.cooldown
	
	if anim_tree:
		anim_tree.set("parameters/FireOneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		
	var success: bool = equipped_weapon.use(self)
	weapon_equipped.emit(equipped_weapon)

	if equipped_weapon is Grenade and success:
		_on_grenade_thrown()

func _try_reload() -> void:
	if equipped_weapon == null: return
	if equipped_weapon.has_method("reload"):
		equipped_weapon.reload(self)
		weapon_equipped.emit(equipped_weapon)
		
		if anim_tree:
			anim_tree.set("parameters/ReloadOneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

func equip_weapon(weapon: Weapon) -> void:
	if current_weapon_model:
		current_weapon_model.queue_free()
		current_weapon_model = null

	equipped_weapon = weapon
	weapon_equipped.emit(weapon)

	if weapon and weapon.model_scene:
		current_weapon_model = weapon.model_scene.instantiate()
		
		# Сбрасываем трансформацию
		current_weapon_model.scale = Vector3.ONE
		current_weapon_model.rotation = Vector3.ZERO
		current_weapon_model.position = Vector3.ZERO

		if weapon_mount:
			weapon_mount.add_child(current_weapon_model)
		else:
			print("[Ошибка] WeaponMount не найден по пути: model/Armature/Skeleton3D/BoneAttachment3D/WeaponMount")
			add_child(current_weapon_model)

		is_aiming = true 
	else:
		is_aiming = false 

	if weapon:
		print("[Player] Экипировано: ", weapon.name)
	else:
		print("[Player] Оружие снято")

func _push_rigidbodies(delta: float) -> void:
	if push_area == null: return
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if input_dir.length() < 0.1: return
	var forward := -(global_position - camera.global_position)
	forward.y = 0
	forward = forward.normalized()
	var right := -(forward.cross(Vector3.UP).normalized())
	var move_dir: Vector3 = (right * input_dir.x + forward * input_dir.y).normalized()

	for body in push_area.get_overlapping_bodies():
		if not (body is RigidBody3D): continue
		body.apply_central_impulse(move_dir * push_strength * delta)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"): GameManager.toggle_pause()

	if event.is_action_pressed("interact"):
		if not get_tree().get_nodes_in_group("chest_ui").is_empty(): return
		if current_pickup and is_instance_valid(current_pickup):
			current_pickup.interact(self)
			_update_pickup_ui()
		elif current_interactable: current_interactable.interact(self)

	if event.is_action_pressed("attack"): _try_attack()
	if event.is_action_pressed("reload"): _try_reload()
	if event.is_action_pressed("drop"): _drop_equipped_weapon()

	for i in range(9):
		if event.is_action_pressed("hotbar_" + str(i + 1)):
			_hotbar_equip(i)
			return

	if event.is_action_pressed("save_game"): SaveSystem.save_game(0)
	if event.is_action_pressed("load_game"): SaveSystem.load_game(0)

func _hotbar_equip(index: int) -> void:
	if hotbar == null: return
	var weapon = hotbar.get_slot(index)
	if weapon == null:
		print("[Player] Хотбар слот ", index + 1, " пуст")
		return
	equip_weapon(weapon)

func _on_grenade_thrown() -> void:
	var grenade = equipped_weapon as Grenade
	if grenade == null: return
	if grenade.current_ammo > 0:
		weapon_equipped.emit(equipped_weapon)
		return
	if hotbar:
		var slot_idx := hotbar.find_slot_of(grenade)
		if slot_idx >= 0: hotbar.clear_slot(slot_idx)
	equip_weapon(null)
	print("[Player] Гранаты кончились")

func _drop_equipped_weapon() -> void:
	if equipped_weapon == null:
		print("[Player] Нечего выбрасывать")
		return
	var old = equipped_weapon
	equip_weapon(null)
	if hotbar:
		var idx := hotbar.find_slot_of(old)
		if idx >= 0: hotbar.clear_slot(idx)

	var pickup_scene := load("res://systems/interaction/PickupItem.tscn")
	if pickup_scene == null: return

	var count: int = 1
	if old is Grenade:
		var grenade = old as Grenade
		count = grenade.current_ammo
		if count <= 0: return

	var pickup = pickup_scene.instantiate()
	pickup.item = old
	pickup.amount = count

	var forward: Vector3 = -global_transform.basis.z
	forward.y = 0
	forward = forward.normalized()
	var spawn_pos: Vector3 = global_position + forward * 1.5 + Vector3.UP * 1.0
	pickup.position = spawn_pos
	get_tree().current_scene.add_child(pickup)
	pickup.global_position = spawn_pos

	if pickup is RigidBody3D:
		var throw_dir: Vector3 = (forward + Vector3.UP * 0.3).normalized()
		pickup.apply_central_impulse(throw_dir * 3.0)

	weapon_equipped.emit(null)

func _rotate_to_mouse(delta: float) -> void:
	if camera == null: return
	var mouse_pos := get_viewport().get_mouse_position()
	var from := camera.project_ray_origin(mouse_pos)
	var to := from + camera.project_ray_normal(mouse_pos) * 1000
	var space := get_world_3d().direct_space_state
	var params := PhysicsRayQueryParameters3D.create(from, to)
	params.exclude = [self]
	var result := space.intersect_ray(params)

	var target_point: Vector3
	if result: target_point = result.position
	else:
		var plane := Plane(Vector3.UP, global_position.y)
		var intersect = plane.intersects_ray(from, to - from)
		if intersect == null: return
		target_point = intersect

	var dir := global_position - target_point
	dir.y = 0
	if dir.length() < 0.1: return
	var target_angle := atan2(dir.x, dir.z)
	rotation.y = lerp_angle(rotation.y, target_angle, delta * rotation_speed)

func _update_interaction() -> void:
	var collider := raycast.get_collider()
	var new_interactable: Interactable = null
	if collider is Interactable: new_interactable = collider

	if new_interactable != current_interactable:
		if current_interactable: current_interactable.hide_highlight()
		current_interactable = new_interactable
		if current_interactable:
			current_interactable.show_highlight()
			if hud and current_pickup == null:
				hud.show_prompt("[F] " + current_interactable.get_prompt())
		else:
			if hud and current_pickup == null: hud.hide_prompt()

func _on_pickup_area_entered(body: Node) -> void:
	if body.is_in_group("pickup"):
		nearby_pickups.append(body)
		_update_pickup_ui()

func _on_pickup_area_exited(body: Node) -> void:
	if body.is_in_group("pickup"):
		nearby_pickups.erase(body)
		if body.has_method("hide_highlight"): body.hide_highlight()
		if body == current_pickup: current_pickup = null
		_update_pickup_ui()

func _update_pickup_ui() -> void:
	nearby_pickups = nearby_pickups.filter(func(x): return is_instance_valid(x))
	for p in nearby_pickups:
		if p.has_method("hide_highlight"): p.hide_highlight()

	if nearby_pickups.is_empty():
		current_pickup = null
		if current_interactable and hud: hud.show_prompt("[F] " + current_interactable.get_prompt())
		elif hud: hud.hide_prompt()
		return

	var closest: Node = null
	var min_dist: float = INF
	for p in nearby_pickups:
		var d: float = global_position.distance_to(p.global_position)
		if d < min_dist:
			min_dist = d
			closest = p

	current_pickup = closest
	if current_pickup and current_pickup.has_method("show_highlight"): current_pickup.show_highlight()
	if current_pickup and hud: hud.show_prompt("[F] " + current_pickup.get_prompt())

func equip_armor(armor: Armor) -> void:
	if current_armor_model:
		current_armor_model.queue_free()
		current_armor_model = null
	equipped_armor = armor
	armor_equipped.emit(armor)
	if armor and armor.model_scene and armor_mount:
		current_armor_model = armor.model_scene.instantiate()
		armor_mount.add_child(current_armor_model)
	_update_armor_stat()

func equip_helmet(helmet: Helmet) -> void:
	if current_helmet_model:
		current_helmet_model.queue_free()
		current_helmet_model = null
	equipped_helmet = helmet
	helmet_equipped.emit(helmet)
	if helmet and helmet.model_scene and helmet_mount:
		current_helmet_model = helmet.model_scene.instantiate()
		helmet_mount.add_child(current_helmet_model)
	_update_armor_stat()

func _update_armor_stat() -> void:
	var total: int = 0
	if equipped_armor: total += equipped_armor.armor_value
	if equipped_helmet: total += equipped_helmet.armor_value
	health.armor = total

func unequip_weapon() -> void:
	if equipped_weapon == null: return
	var old = equipped_weapon
	equip_weapon(null)
	if hotbar:
		var idx := hotbar.find_slot_of(old)
		if idx >= 0: hotbar.clear_slot(idx)
	if inventory:
		if old is Grenade:
			var grenade = old as Grenade
			if grenade.current_ammo > 0: inventory.add_item(old, grenade.current_ammo)
		else: inventory.add_item(old, 1)
	weapon_equipped.emit(null)

func _on_inventory_changed() -> void:
	if equipped_weapon: weapon_equipped.emit(equipped_weapon)

func _on_damaged(amount: int, current: int, max_hp: int) -> void:
	print("HP: ", current, "/", max_hp)

func _on_died() -> void:
	print("[Player] Умер")
