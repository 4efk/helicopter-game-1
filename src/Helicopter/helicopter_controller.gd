extends RigidBody3D

@export var coefficient_lift = 0.0
@export var main_rotor_blades_n = 2
@export var main_rotor_area = 46.20 #main rotor disc area in m^2

@onready var main_rotor_pos = $MainRotorPos.position
@onready var tail_rotor_pos = $TailRotorPos.position

var main_rotor_omega =  55.50 #angular velocity [rad/s]

func _ready():
	pass

func _process(delta):
	if Input.is_action_just_pressed("start_engine"):
		main_rotor_omega = 55.50
	if Input.is_action_just_pressed("stop_engine"):
		main_rotor_omega = 0
	
func _physics_process(delta):
	coefficient_lift = 1.225 * main_rotor_area * 0.1
	
	apply_force(transform.basis.y * 0.5 * main_rotor_omega * main_rotor_omega * coefficient_lift * main_rotor_blades_n, main_rotor_pos)
		
	#print(Vector3(-0.5, 0.5, 0) * 0.5 * main_rotor_omega * coefficient_lift * main_rotor_blades_n)# * (0.5 * main_rotor_omega * coefficient_lift * main_rotor_blades_n))
	print(linear_velocity)
