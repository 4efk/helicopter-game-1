extends Node3D

@onready var moving_main_rotor_part = $World/Helicopter/helicopter1_model_2/MovingMainRotorPart
@onready var moving_tail_rotor_part = $World/Helicopter/helicopter1_model_2/MovingTailRotorPart

@onready var main_menu = $CanvasLayer/MainMenu
@onready var settings = $CanvasLayer/Settings

@onready var freeflight_button = $CanvasLayer/MainMenu/VBoxContainer/FFButton

@onready var bg_music = $BGMusic

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	GlobalScript.flightschool_checkpoint = GlobalScript.DEFAULT_FLIGHTSCHOOL_CHECKPOINT.duplicate()
	
	freeflight_button.disabled = !GlobalScript.game_save['freeflight_unlocked']
	
	$CanvasLayer/MainMenu/VBoxContainer/FSButton.grab_focus()

func _process(delta):
	var main_rotor_omega = 2
	var tail_rotor_omega = 355.62828798/55.5 * main_rotor_omega
	
	moving_main_rotor_part.quaternion *= Quaternion(Vector3(0.0471064507, 0.99888987496, 0), main_rotor_omega * delta)
	moving_tail_rotor_part.quaternion *= Quaternion(Vector3(0, 0, 1), tail_rotor_omega * delta)
	
	if !bg_music.playing:
		bg_music.play()

func _on_button_pressed():
	GlobalScript.current_gamemode = 1
	get_tree().change_scene_to_file("res://World/free_flight.tscn")

func _on_button_2_pressed():
	GlobalScript.current_gamemode = 0
	get_tree().change_scene_to_file("res://World/flight_school.tscn")

func _on_settings_button_pressed():
	main_menu.hide()
	settings.show()

func _on_quit_button_pressed():
	get_tree().quit()
