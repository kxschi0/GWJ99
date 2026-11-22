extends Node3D

@export var correct_password = "3954"

var is_audio_playing = false
var password = ""
var is_unlocked = false 

signal on_correct_password(password)
signal on_wrong_password(password)
signal on_clear_password(password)
signal on_keypad_press(password)

@onready var pressed_audio = $PressedAudioStream
@onready var correct_audio = $CorrectAudioStream
@onready var wrong_audio = $WrongAudioStream

@onready var keys = $Keys
@onready var password_label = $PasswordViewport/PasswordLabel

func _ready():
	is_unlocked = false 
	password = ""
	password_label.text = ""

	for child in keys.get_children():
		if child is StaticBody3D:
			if not child.is_connected("on_interact", Callable(self, "on_button_interact")):
				child.connect("on_interact", Callable(self, "on_button_interact"))

func on_button_interact(value):
	if is_unlocked or is_audio_playing:
		return

	is_audio_playing = true
	if pressed_audio:
		pressed_audio.playing = true

	print("interacted with " + value)

	# Enter gomb (".") lenyomása
	if value == ".":
		if password == correct_password:
			if correct_audio:
				correct_audio.play()
			is_unlocked = true 
			password_label.text = "OPEN" 
			
			emit_signal("on_correct_password", password)
		else:
			if wrong_audio:
				wrong_audio.play()
			emit_signal("on_wrong_password", password)
			password = ""

	elif value == "C":
		emit_signal("on_clear_password", password)
		password = ""

	else:
		if password.length() == correct_password.length():
			is_audio_playing = false
			return
		password += value
		emit_signal("on_keypad_press", password)

	if not is_unlocked:
		password_label.text = password

func _on_AudioStreamPlayer3D_finished():
	is_audio_playing = false
