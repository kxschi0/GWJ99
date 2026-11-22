extends Node3D

func _ready() -> void:
	set_visual_layer(self)

func set_visual_layer(node: Node3D) -> void:
	for child in node.get_children(true):
		print(child.name)
		if child is CharacterBody3D:
			continue
		elif child is MeshInstance3D:
			child.set_layer_mask_value(1, false)
			child.set_layer_mask_value(2, true)
		if child.get_child_count(true) > 0:
			set_visual_layer(child)
