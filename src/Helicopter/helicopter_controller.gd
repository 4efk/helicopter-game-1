extends RigidBody3D

@export var thrust_coefficient = 0.0
@export var main_rotor_blades_n = 2
@export var main_rotor_radius = 3.835 # radius of the main rotor disc [m]
@export var second_rotor_radius = 0.0

@export var main_rotor_collective_max = 12 # max/min angle of main rotor blades [°]; made up
@export var main_rotor_collective_min = -12

@onready var main_rotor_pos = $MainRotorPos.global_position
@onready var tail_rotor_pos = $TailRotorPos.global_position

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
	
func _physics_process(_delta):
	
	main_rotor_pos = $MainRotorPos.global_position
	tail_rotor_pos = $TailRotorPos.global_position
	
	
	
	var main_rotor_thrust_force = 0.5 * GlobalScript.air_density * pow(main_rotor_omega * main_rotor_radius, 2) * PI * pow(main_rotor_radius, 2) * main_rotor_collective_pitch * 0.001
	#print(main_rotor_thrust_force)
	
	#print(Input.get_vector("cyclic_backward", "cyclic_forward", "cyclic_left", "cyclic_right"))
	
	cyclic = Input.get_vector("cyclic_backward", "cyclic_forward", "cyclic_left", "cyclic_right")
	
	print(cyclic)
	
	
	#the direction doesn't take y rotation into account so that's why it's offset and broken
	
	var main_rotor_thrust_direction = transform.basis.y.rotated(Vector3(1, 0, 0), cyclic.x * PI/30).rotated(Vector3(0, 0, 1), cyclic.y * PI/30)
	main_rotor_thrust_direction = Vector3.UP.rotated(Vector3(1, 0, 0), cyclic.x * PI/30).rotated(Vector3(0, 0, 1), cyclic.y * PI/30)
	
	$markers/MainRotorThrustMarker.rotation = Vector3(main_rotor_thrust_direction.x, 0, main_rotor_thrust_direction.z)
	$markers/MainRotorThrustMarker.global_position = main_rotor_pos
	#print(main_rotor_thrust_direction)
	#print(main_rotor_pos - global_position)
	#print(main_rotor_thrust_direction)
	
	
	apply_force(Vector3(0, 1, 0) * 5000, main_rotor_pos)
	#apply_central_force(main_rotor_thrust_direction * main_rotor_thrust_force)
	#apply_force(main_rotor_thrust_direction * main_rotor_thrust_force, main_rotor_pos)
	
	#apply_force(Vector3(0, 500 * 9.8, 0), main_rotor_pos)
	
	#if Input.is_action_pressed("start_engine"):
		#apply_force(main_rotor_thrust_direction * main_rotor_thrust_force, main_rotor_pos)
	
	#print(main_rotor_thrust_direction)
	#apply_torque(Vector3(0, -256.45 , 0))
	
	var tail_rotor_thrust_force = 64.47 + Input.get_axis("antitorque_right", "antitorque_left") * 400#2523.46
	var tail_rotor_thrust_direction = transform.basis.z
	
	#apply_force(tail_rotor_thrust_direction * tail_rotor_thrust_force, tail_rotor_pos)
	
	#print(linear_velocity)
