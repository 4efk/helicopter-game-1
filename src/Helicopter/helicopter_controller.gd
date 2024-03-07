extends RigidBody3D

@export var thrust_coefficient = 0.0
@export var main_rotor_blades_n = 2
@export var main_rotor_radius = 3.835 # diameter of the main rotor disc [m^2]
@export var second_rotor_radius = 0

@export var main_rotor_collective_max = 12 # max/min angle of main rotor blades [°]; made up
@export var main_rotor_collective_min = -12

@onready var main_rotor_pos = $MainRotorPos.position
@onready var tail_rotor_pos = $TailRotorPos.position

var main_rotor_omega =  55.50 # angular velocity [rad/s]

var main_rotor_collective_pitch = 0.0
var cyclic = Vector2()

func _ready():
	pass

func _process(delta):
	if Input.is_action_just_pressed("start_engine"):
		main_rotor_omega = 55.50
	if Input.is_action_just_pressed("stop_engine"):
		main_rotor_omega = 0
		
	main_rotor_collective_pitch += Input.get_axis("collective_pitch_down", "collective_pitch_up") * delta * 10
	main_rotor_collective_pitch = clamp(main_rotor_collective_pitch, main_rotor_collective_min, main_rotor_collective_max)
	
func _physics_process(delta):
	var main_rotor_thrust_force = 0.5 * GlobalScript.air_density * pow(main_rotor_omega * main_rotor_radius, 2) * PI * pow(main_rotor_radius, 2) * main_rotor_collective_pitch * 0.001
	#print(main_rotor_thrust_force)
	
	#print(Input.get_vector("cyclic_backward", "cyclic_forward", "cyclic_left", "cyclic_right"))
	
	cyclic = Input.get_vector("cyclic_backward", "cyclic_forward", "cyclic_right", "cyclic_left")
	
	var main_rotor_thrust_direction = transform.basis.y.rotated(Vector3(1, 0, 0), cyclic.y * PI/12).rotated(Vector3(0, 0, 1), cyclic.x * PI/12)
	
	#apply_central_force(main_rotor_thrust_direction * main_rotor_thrust_force)
	apply_force(main_rotor_thrust_direction * main_rotor_thrust_force, main_rotor_pos)
	print(main_rotor_thrust_direction)
	
	#print(linear_velocity)
