extends Node3D

var text_to_type = 'do not crash'
var typing_delay = 0.2

@onready var hint_text = $WorldHUD/HintText

var timer = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if timer >= typing_delay and len(hint_text.text) != len(text_to_type):
		hint_text.text += text_to_type[len(text_to_type) - len(hint_text.text) - 1]
		timer = 0
	timer += delta
