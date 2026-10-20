extends Area3D

var direction: Vector3 = Vector3.FORWARD
var speed: float = 25.0
var damage: int = 10
var lifetime: float = 3.0
var owner_node: Node = null

func setup(dir: Vector3, spd: float, dmg: int, shooter: Node = null) -> void:
	direction = dir.normalized()
	speed = spd
	damage = dmg
	owner_node = shooter

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body == owner_node:
		return
	if body.is_in_group("player"):
		var health = body.get_node_or_null("HealthComponent")
		if health:
			health.take_damage(damage)
			print("[EnemyProjectile] Попал по игроку на ", damage)
	queue_free()
