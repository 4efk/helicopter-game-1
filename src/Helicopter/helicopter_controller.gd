extends RigidBody3D

var main_rotor_rpm = 0.0

@onready var main_rotor_pos = $MainRotorPos.position
@onready var tail_rotor_pos = $TailRotorPos.position

func _ready():
	pass # Replace with function body.

func _process(delta):
	pass
	
func _physics_process(delta):
	if Input.is_action_pressed("ui_accept"):
		apply_force(Vector3(0, 5000, 0), main_rotor_pos)
