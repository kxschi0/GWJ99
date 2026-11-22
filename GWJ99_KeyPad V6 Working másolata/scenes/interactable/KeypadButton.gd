@tool
extends Interactable

@export var number = "0": set = set_number

var interaction_text = "interact with keypad button"
var is_unlocked = false 

signal on_interact

func set_number(value):
	number = value
	if value:
		if has_node("SubViewport/Label"):
			$SubViewport/Label.text = str(value)

func get_interaction_text():
	if is_unlocked:
		return ""
	return interaction_text

func interact():
	if is_unlocked:
		return
	emit_signal("on_interact", number)

func disable_interaction():
	is_unlocked = true
	interaction_text = ""
	
	for child in get_children():
		if child is CollisionShape3D:
			child.disabled = true
			

	for child in get_children():
		if child is MeshInstance3D or child is Sprite3D:
			child.visible = false
