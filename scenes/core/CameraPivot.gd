extends SpringArm3D

## Изометрическая камера: следует за игроком, зумит, поворачивается.

@export var target_path: NodePath
@export var follow_speed: float = 10.0 # Увеличил скорость, чтобы не было "резинового" эффекта
@export var zoom_speed: float = 1.5
@export var min_zoom: float = 6.0
@export var max_zoom: float = 20.0
@export var rotation_step: float = deg_to_rad(45)
@export var rotation_smooth: float = 10.0

var target: Node3D
var yaw_target: float = 0.0

func _ready() -> void:
	if target_path:
		target = get_node(target_path)
	yaw_target = rotation.y

func _physics_process(delta: float) -> void:
	# Слежение за игроком в физическом процессе (синхронизация с телом игрока)
	if target:
		var target_pos := target.global_transform.origin
		# Берем позицию игрока, но оставляем высоту камеры неизменной
		var desired := Vector3(target_pos.x, global_position.y, target_pos.z)
		
		# Используем move_toward для жесткой привязки без "дрожания"
		# Если хочешь легкую плавность (резинку), замени на lerp
		var distance = global_position.distance_to(desired)
		if distance > 0.01:
			global_position = global_position.move_toward(desired, follow_speed * delta)

	# Плавный поворот (в физическом процессе)
	rotation.y = lerp_angle(rotation.y, yaw_target, delta * rotation_smooth)

func _unhandled_input(event: InputEvent) -> void:
	# Зум колёсиком
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			spring_length = clamp(spring_length - zoom_speed, min_zoom, max_zoom)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			spring_length = clamp(spring_length + zoom_speed, min_zoom, max_zoom)

	# Вращение Q/E
	if event.is_action_pressed("camera_rotate_left"):
		yaw_target += rotation_step
	if event.is_action_pressed("camera_rotate_right"):
		yaw_target -= rotation_step

func set_target(node: Node3D) -> void:
	target = node
