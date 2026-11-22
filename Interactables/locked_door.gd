extends Interactable

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _on_interaction() -> void:
	var keys: int = get_tree().current_scene.keys_collected
	if keys < 3:
		return
	monitorable = false
	interaction_text = ""
	animation_player.play("door_autoCloseOpen")


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	monitorable = true
	interaction_text = "Open Door"
