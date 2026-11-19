class_name Interactable extends Area3D

@export var interaction_text: String = "Interact"

func _init() -> void:
	set_collision_layer_value(3, true)

func _on_interaction() -> void:
	printerr("No interaction was defined for {0}".format([name]))
