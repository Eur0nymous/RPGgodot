extends Node3D

@onready var chips: CPUParticles3D = $Chips
@onready var dust: CPUParticles3D = $Dust

func _ready() -> void:
	if chips:
		chips.emitting = true
	if dust:
		dust.emitting = true
	await get_tree().create_timer(2.0).timeout
	queue_free()
