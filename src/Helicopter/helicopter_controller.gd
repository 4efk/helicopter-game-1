extends RigidBody3D

@export var coefficient_lift = 0.0
@export var main_rotor_blades_n = 2

var main_rotor_omega = 55.50 #angular velocity [rad/s]

@onready var main_rotor_pos = $MainRotorPos.position
@onready var tail_rotor_pos = $TailRotorPos.position

func _ready():
	pass

func _process(delta):
	if Input.is_action_just_pressed("start_engine"):
		main_rotor_omega = 55.50
	if Input.is_action_just_pressed("stop_engine"):
		main_rotor_omega = 0
	
func _physics_process(delta):
	coefficient_lift = 1.225 * 10 * 10
	
	apply_central_force(transform.basis.y.round().normalized() * 0.5 * main_rotor_omega * coefficient_lift * main_rotor_blades_n)#, main_rotor_pos)
		
	print(transform.basis.y.round() * 0.5 * main_rotor_omega * coefficient_lift * main_rotor_blades_n)
