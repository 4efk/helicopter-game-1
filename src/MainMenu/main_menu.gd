extends CanvasLayer

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_button_pressed():
	GlobalScript.current_gamemode = 1
	get_tree().change_scene_to_file("res://World/world_0.tscn")

func _on_button_2_pressed():
	GlobalScript.current_gamemode = 0
	get_tree().change_scene_to_file("res://World/flight_school.tscn")
