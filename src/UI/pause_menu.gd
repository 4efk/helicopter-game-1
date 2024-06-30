extends Control

@onready var retry_button = $HBoxContainer/RetryButton

func _ready():
	hide()

func _process(delta):
	if Input.is_action_just_pressed("pause"):
		print(1)
		if GlobalScript.unpausable:
			return
		print(2)
		visible = !visible
		get_tree().paused = !get_tree().paused
		if get_tree().paused:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			retry_button.grab_focus()
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_retry_button_pressed():
	if GlobalScript.current_gamemode == 0:
		get_tree().paused = false
		get_node("../../").player_die()
		get_tree().change_scene_to_file("res://World/flight_school.tscn")
	else:
		get_tree().paused = false
		get_tree().change_scene_to_file("res://World/free_flight.tscn")

func _on_main_menu_button_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://MainMenu/main_menu.tscn")
