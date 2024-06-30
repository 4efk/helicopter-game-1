extends RigidBody3D

@onready var camera = $Camera3D

@onready var look_at_position = get_parent().get_parent().global_position

func _ready():
	camera.look_at(look_at_position)
	camera.current = true

func _process(delta):
	#global_position = get_parent().global_position + Vector3(8, 8, 8)
	camera.look_at(look_at_position)
	if global_position.y < 1:
		global_position.y = 1
