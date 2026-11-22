extends Node

@onready var player: CharacterBody3D = null
@onready var hud: Control = $Vision/HUD

@onready var normal_vision: ColorRect = $Vision/NormalVision
@onready var other_vision: ColorRect = $Vision/OtherVision
@onready var madness_rim: ColorRect = $Vision/MadnessRim

var keys_collected: int = 0
var exit_doors: Array = []

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")
	player.interact_ray.enabled = true
	
	exit_doors = get_tree().get_nodes_in_group("ExitDoor")
	
	SignalBus.key_collected.connect(_on_key_collected)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		for player_instance in get_tree().get_nodes_in_group("Player"):
			player_instance.camera_relative = event.relative
	
func _process(delta: float) -> void:
	other_vision.material.set_shader_parameter("alpha", player.peek_transition)
	madness_rim.material.set_shader_parameter("alpha", player.madness)

func _on_key_collected() -> void:
	keys_collected += 1
	if keys_collected == 3:
		exit_doors[0].interaction_text = "Unlock Door"
		exit_doors[1].interaction_text = "Unlock Door"
