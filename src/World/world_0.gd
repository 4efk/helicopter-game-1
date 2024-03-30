extends Node3D

var text_to_type = 'test'
var typing_delay = 0.1
@onready var hint_text = $WorldHUD/HintText

var timer = 0

func _ready():
	randomize()

func _process(delta):
	if timer >= typing_delay and len(hint_text.text) != len(text_to_type):
		hint_text.text += text_to_type[len(hint_text.text)]
		typing_delay = randf_range(0.05, 0.2)
		timer = 0
	timer += delta
