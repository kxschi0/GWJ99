extends Control

@onready var crosshair: TextureRect = $Crosshair
@onready var interact_label: Label = $InteractLabel

func show_interaction_text(interaction_text: String) -> void:
	interact_label.text = interaction_text
	crosshair.visible = interaction_text == ""
	interact_label.show()

func hide_interaction_text() -> void:
	interact_label.hide()
	interact_label.text = ""
	crosshair.show()
