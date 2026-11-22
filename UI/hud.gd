extends Control

@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var crosshair: TextureRect = $Crosshair
@onready var interact_label: Label = $InteractLabel

func _ready() -> void:
	SignalBus.exit_reached.connect(_on_exit_reached)

func show_interaction_text(interaction_text: String) -> void:
	interact_label.text = interaction_text
	crosshair.visible = interaction_text == ""
	interact_label.show()

func hide_interaction_text() -> void:
	interact_label.hide()
	interact_label.text = ""
	crosshair.show()

func _on_exit_reached() -> void:
	animation_player.play("WinScreen")
	await get_tree().create_timer(2.0).timeout
	get_tree().current_scene.player.disable_movement()
