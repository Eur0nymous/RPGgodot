extends Area3D
class_name Interactable

signal interacted(player: Node)

@export var prompt: String = "Взаимодействовать"
@export var enabled: bool = true
@export var highlight_color: Color = Color(1, 0.8, 0.2)
@export var highlight_energy: float = 2.0
@export var dialogue_resource: Resource
@export var dialogue_start: String = "start"

@onready var mesh: MeshInstance3D = get_node_or_null("MeshInstance3D")

var _original_material: Material
var _highlight_material: StandardMaterial3D

func _ready() -> void:
	if mesh == null:
		return
	_original_material = mesh.material_override
	if _original_material == null:
		var temp := StandardMaterial3D.new()
		temp.albedo_color = Color(0.5, 0.5, 0.5)
		mesh.material_override = temp
		_original_material = temp
	_highlight_material = _original_material.duplicate() as StandardMaterial3D
	_highlight_material.emission_enabled = true
	_highlight_material.emission = highlight_color
	_highlight_material.emission_energy_multiplier = highlight_energy

func interact(player: Node) -> void:
	if not enabled:
		return
	print("[Interactable] ", name, " interacted by ", player.name)
	if dialogue_resource:
		DialogueManager.show_example_dialogue_balloon(dialogue_resource, dialogue_start)
	interacted.emit(player)

func get_prompt() -> String:
	return prompt

func show_highlight() -> void:
	if mesh and _highlight_material:
		mesh.material_override = _highlight_material

func hide_highlight() -> void:
	if mesh and _original_material:
		mesh.material_override = _original_material
