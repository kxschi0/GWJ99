extends Node3D

@export var correct_password = "3954"

var is_audio_playing = false
var password = ""
var is_unlocked = false # Új változó: figyeli, hogy ki van-e már nyitva

signal on_correct_password
signal on_wrong_password
signal on_clear_password
signal on_keypad_press

@onready var pressed_audio = $PressedAudioStream
@onready var correct_audio = $CorrectAudioStream
@onready var wrong_audio = $WrongAudioStream

@onready var keys = $Keys
@onready var password_label = $PasswordViewport/PasswordLabel

func _ready():
	for child in keys.get_children():
		if child is StaticBody3D:
			child.connect("on_interact", Callable(self, "on_button_interact"))

	password_label.text = ""

func on_button_interact(value):
	# Ha már ki van nyitva a széf, vagy megy a hang, ne csináljon semmit
	if is_unlocked or is_audio_playing:
		return

	is_audio_playing = true
	pressed_audio.playing = true

	print("interacted with " + value)

	# enter key is pressed
	if value == ".":
		# check if the number is the correct number
		if password == correct_password:
			correct_audio.play()
			is_unlocked = true # Zárjuk a billentyűzetet, többet nem reagál
			password_label.text = "OPEN" # Opcionális: kiírhatja, hogy nyitva
			emit_signal("on_correct_password", password)
			
			# ITT NYÍLHAT MEG AZ AJTÓ:
			# Meghívhatsz egy függvényt a széf / ajtó csomópontján, pl:
			# get_node("../AjtóCsomópontNeve").nyisd_ki()
			
		else:
			wrong_audio.play()
			emit_signal("on_wrong_password", password)
			password = ""

	# clear key is pressed
	elif value == "C":
		# clear the current number
		emit_signal("on_clear_password", password)
		password = ""

	# digit key is pressed
	else:
		# got a number value
		if password.length() == correct_password.length():
			return
		password += value
		emit_signal("on_keypad_press", password)

	if not is_unlocked:
		password_label.text = password

func _on_AudioStreamPlayer3D_finished():
	is_audio_playing = false
