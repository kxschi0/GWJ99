extends Node3D

var animation_player: AnimationPlayer = null
var keypad_sprite: Sprite3D = null
var interaction_label: Label = null

func _ready():
	print("starting")
	
	if has_node("Keypad/safe_GWJ99/AnimationPlayer"):
		animation_player = get_node("Keypad/safe_GWJ99/AnimationPlayer")
	elif has_node("Keypad"):
		animation_player = find_animation_player_in($Keypad)

	if has_node("Keypad/Sprite3D"):
		keypad_sprite = get_node("Keypad/Sprite3D")
	elif has_node("Keypad"):
		keypad_sprite = find_sprite_in($Keypad)

	if has_node("UI/InteractionLabel"):
		interaction_label = get_node("UI/InteractionLabel")
	else:
		interaction_label = find_interaction_label_in(self)

	if has_node("Keypad"):
		var keypad = $Keypad
		if keypad.has_signal("on_correct_password"):
			if not keypad.is_connected("on_correct_password", Callable(self, "_on_Keypad_on_correct_password")):
				keypad.connect("on_correct_password", Callable(self, "_on_Keypad_on_correct_password"))

func find_animation_player_in(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var found = find_animation_player_in(child)
		if found:
			return found
	return null

func find_sprite_in(node: Node) -> Sprite3D:
	if node is Sprite3D:
		return node
	for child in node.get_children():
		var found = find_sprite_in(child)
		if found:
			return found
	return null

func find_interaction_label_in(node: Node) -> Node:
	if node.name == "InteractionLabel":
		return node
	for child in node.get_children():
		var found = find_interaction_label_in(child)
		if found:
			return found
	return null

func _on_Keypad_on_correct_password(_password):
	print("working")
	
	if animation_player and animation_player.has_animation("open"):
		animation_player.play("open", -1, 1.0, false)
	
	if keypad_sprite:
		keypad_sprite.visible = false
	
	if interaction_label:
		interaction_label.visible = false
	
	if has_node("Keypad/Keys"):
		for key in $Keypad/Keys.get_children():
			if key.has_method("disable_interaction"):
				key.disable_interaction()
