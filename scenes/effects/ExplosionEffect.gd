extends Node3D

@onready var light: OmniLight3D = get_node_or_null("Light")
@onready var fire: CPUParticles3D = get_node_or_null("Fire")
@onready var smoke: CPUParticles3D = get_node_or_null("Smoke")
@onready var spark: CPUParticles3D = get_node_or_null("Spark")

func _ready() -> void:
	# Форсим локальные координаты — частицы летят от эмиттера
	for p in [fire, smoke, spark]:
		if p == null:
			continue
		p.local_coords = true
		# Сбрасываем позицию до нуля (родитель = точка взрыва)
		p.position = Vector3.ZERO
		p.rotation = Vector3.ZERO
		p.emitting = true

	# Вспышка гаснет
	if light:
		light.position = Vector3(0, 0.5, 0)
		var tween := create_tween()
		tween.tween_property(light, "light_energy", 0.0, 0.3)

	await get_tree().create_timer(2.0).timeout
	queue_free()
