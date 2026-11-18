extends Node

@onready var player: CharacterBody3D = null

@onready var normal_vision: ColorRect = $Vision/NormalVision
@onready var other_vision: ColorRect = $Vision/OtherVision
@onready var madness_rim: ColorRect = $Vision/MadnessRim

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")
	player.interact_ray.enabled = true

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		for player in get_tree().get_nodes_in_group("Player"):
			player.camera_relative = event.relative
	
func _process(delta: float) -> void:
	normal_vision.material.set_shader_parameter("alpha", 1.0 - player.peek_transition)
	other_vision.material.set_shader_parameter("alpha", player.peek_transition)
	madness_rim.material.set_shader_parameter("alpha", player.madness)
