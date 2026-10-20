extends CharacterBody3D

@export var move_speed: float = 3.0
@export var preferred_range: float = 8.0
@export var min_range: float = 5.0
@export var max_range: float = 12.0
@export var shoot_damage: int = 8
@export var shoot_cooldown: float = 2.0
@export var projectile_scene: PackedScene
@export var projectile_speed: float = 25.0
@export var gravity: float = 20.0

@export var patrol_points: Array[Node3D] = []
@export var patrol_wait_time: float = 1.5
@export var patrol_threshold: float = 1.5

@onready var health: HealthComponent = $HealthComponent
@onready var detection: Area3D = $DetectionArea
@onready var shoot_point: Node3D = get_node_or_null("ShootPoint")
@onready var agent: NavigationAgent3D = $NavigationAgent3D

var player: Node3D = null
var shoot_timer: float = 0.0
var patrol_index: int = 0
var patrol_wait: float = 0.0
var state: String = "patrol"

func _ready() -> void:
	add_to_group("enemy")
	health.died.connect(_on_died)
	detection.body_entered.connect(_on_body_entered)
	detection.body_exited.connect(_on_body_exited)
	shoot_timer = shoot_cooldown * 0.5

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0

	if shoot_timer > 0:
		shoot_timer -= delta

	if player and health.is_alive():
		state = "combat"
		_combat(delta)
	else:
		state = "patrol"
		_patrol(delta)

	move_and_slide()

func _patrol(delta: float) -> void:
	if patrol_points.is_empty():
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)
		return
	if patrol_wait > 0:
		patrol_wait -= delta
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)
		return
	var target = patrol_points[patrol_index]
	if target == null:
		_next_patrol_point()
		return
	var to_target: Vector3 = target.global_position - global_position
	to_target.y = 0
	var dist_to_patrol: float = to_target.length()
	if dist_to_patrol < patrol_threshold:
		_next_patrol_point()
		patrol_wait = patrol_wait_time
		return
	_move_to(target.global_position, delta)

func _next_patrol_point() -> void:
	patrol_index = (patrol_index + 1) % patrol_points.size()

func _combat(delta: float) -> void:
	var dist_to_player: float = global_position.distance_to(player.global_position)
	var dir_to_player: Vector3 = player.global_position - global_position
	dir_to_player.y = 0
	dir_to_player = dir_to_player.normalized()

	if dist_to_player > max_range:
		velocity.x = dir_to_player.x * move_speed
		velocity.z = dir_to_player.z * move_speed
		_face_target(player.global_position, delta)
	elif dist_to_player < min_range:
		velocity.x = -dir_to_player.x * move_speed
		velocity.z = -dir_to_player.z * move_speed
		_face_target(player.global_position, delta)
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)
		_face_target(player.global_position, delta)
		if shoot_timer <= 0:
			_shoot()

func _move_to(target_pos: Vector3, delta: float) -> void:
	var dir: Vector3 = target_pos - global_position
	dir.y = 0
	if dir.length() < 0.1:
		velocity.x = 0
		velocity.z = 0
		return
	dir = dir.normalized()
	velocity.x = dir.x * move_speed
	velocity.z = dir.z * move_speed
	_face_target(target_pos, delta)

func _face_target(target_pos: Vector3, delta: float) -> void:
	var dir: Vector3 = target_pos - global_position
	dir.y = 0
	if dir.length() < 0.1:
		return
	var target_angle := atan2(dir.x, dir.z)
	rotation.y = lerp_angle(rotation.y, target_angle, 8.0 * delta)

func _shoot() -> void:
	shoot_timer = shoot_cooldown
	if projectile_scene == null:
		return
	var proj = projectile_scene.instantiate()
	var spawn_pos: Vector3 = shoot_point.global_position if shoot_point else global_position + Vector3.UP * 1.2
	var dir: Vector3 = (player.global_position + Vector3.UP * 1.0) - spawn_pos
	dir = dir.normalized()
	get_tree().current_scene.add_child(proj)
	proj.global_position = spawn_pos
	if proj.has_method("setup"):
		proj.setup(dir, projectile_speed, shoot_damage, self)
	print("[EnemyRanged] Выстрел")

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player = body
		print("[EnemyRanged] Заметил игрока")

func _on_body_exited(body: Node3D) -> void:
	if body == player:
		player = null
		print("[EnemyRanged] Потерял игрока")

@onready var gibs: GibsComponent = get_node_or_null("GibsComponent")

func _on_died() -> void:
	print("[EnemyRanged] Умер")
	FlagManager.set_flag("enemy_killed", true)
	if gibs:
		gibs.gib(global_position + Vector3.UP * 0.9, Vector3.ZERO)
	queue_free()
