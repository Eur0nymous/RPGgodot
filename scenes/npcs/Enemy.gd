extends CharacterBody3D

@export var move_speed: float = 3.0
@export var attack_range: float = 1.8
@export var attack_damage: int = 10
@export var attack_cooldown: float = 1.5
@export var gravity: float = 20.0

@export var patrol_points: Array[Node3D] = []
@export var patrol_wait_time: float = 1.5
@export var patrol_threshold: float = 1.5

@onready var health: HealthComponent = $HealthComponent
@onready var detection: Area3D = $DetectionArea
@onready var agent: NavigationAgent3D = $NavigationAgent3D

var player: Node3D = null
var attack_timer: float = 0.0
var patrol_index: int = 0
var patrol_wait: float = 0.0
var state: String = "patrol"

func _ready() -> void:
	add_to_group("enemy")
	health.died.connect(_on_died)
	detection.body_entered.connect(_on_body_entered)
	detection.body_exited.connect(_on_body_exited)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0

	if attack_timer > 0:
		attack_timer -= delta

	if player and health.is_alive():
		var dist_to_player: float = global_position.distance_to(player.global_position)
		if dist_to_player <= attack_range:
			state = "attack"
			velocity.x = 0
			velocity.z = 0
			_face_target(player.global_position, delta)
			_try_attack()
		else:
			state = "chase"
			_move_to(player.global_position, delta)
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

func _try_attack() -> void:
	if attack_timer > 0:
		return
	attack_timer = attack_cooldown
	if player:
		var ph = player.get_node_or_null("HealthComponent")
		if ph:
			ph.take_damage(attack_damage)
			print("[Enemy] Атакует игрока на ", attack_damage)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player = body
		print("[Enemy] Заметил игрока")

func _on_body_exited(body: Node3D) -> void:
	if body == player:
		player = null
		print("[Enemy] Потерял игрока")

@onready var gibs: GibsComponent = get_node_or_null("GibsComponent")

func _on_died() -> void:
	print("[Enemy] Умер")
	FlagManager.set_flag("enemy_killed", true)
	if gibs:
		gibs.gib(global_position + Vector3.UP * 0.9, Vector3.ZERO)
	queue_free()
