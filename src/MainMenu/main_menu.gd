extends CanvasLayer

func _on_button_pressed():
	get_tree().change_scene_to_file("res://World/world_0.tscn")

func _on_button_2_pressed():
	get_tree().change_scene_to_file("res://World/world_1.tscn")
