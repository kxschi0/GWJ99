extends Area3D

@onready var animation_player: AnimationPlayer = $"../VisualPivot/MonsterSkin_GWJ99/AnimationPlayer"

var has_triggered: bool = false

func _ready():
	if not is_connected("body_entered", Callable(self, "_on_body_entered")):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D):
	if has_triggered:
		return
		
	if body.is_in_group("player"):
		has_triggered = true
		
		if animation_player and animation_player.has_animation("MonsterJumpscareAttack"):
			animation_player.play("MonsterJumpscareAttack")
			
		
		if body.has_method("disable_movement"):
			body.disable_movement()
			
		var anim_length = 1.5
		if animation_player and animation_player.has_animation("MonsterJumpscareAttack"):
			var anim = animation_player.get_animation("MonsterJumpscareAttack")
			if anim:
				anim_length = max(anim.length, 1.0)
			
		var tree = Engine.get_main_loop() as SceneTree
		if tree:
			tree.create_timer(anim_length).timeout.connect(_on_jumpscare_finished)

func _on_jumpscare_finished():
	var tree = Engine.get_main_loop() as SceneTree
	if tree:
		if tree.current_scene and not tree.current_scene.scene_file_path.is_empty():
			tree.change_scene_to_file(tree.current_scene.scene_file_path)
		else:
			tree.reload_current_scene()
