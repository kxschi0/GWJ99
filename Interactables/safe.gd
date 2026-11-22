extends Interactable

@onready var animation_player: AnimationPlayer = $safe_GWJ99/AnimationPlayer

var is_open: bool = false

func _on_interaction() -> void:
	if is_open:
		return
	
	is_open = true
	animation_player.play("open")
	interaction_text = ""
