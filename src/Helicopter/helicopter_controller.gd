extends RigidBody3D

@export var main_rotor_radius = 3.835 # radius of the main rotor disc [m]
@export var main_rotor_blades_n = 2
@export var main_rotor_collective_max = 12 # max/min angle of main rotor blades [°]; kinda made up
@export var main_rotor_collective_min = 0

@export var tail_rotor_radius = 0.535
@export var tail_rotor_collective_max = 15 # max/min angle of tail rotor blades [°]; kinda extracted from the airfoil AOA/lift coefficient graph
@export var tail_rotor_collective_min = -15

@export var drag_coefficient = 0.36

@export var camera_rotation_speed = 2
@export var mouse_sensitivity = 0.005

@onready var main_rotor_pos_ind = $helicopter0_model_test2/MainRotorPosInd
@onready var tail_rotor_pos_ind = $helicopter0_model_test2/TailRotorPosInd

@onready var moving_main_rotor_part = $helicopter0_model_test2/MovingMainRotorPart
@onready var moving_tail_rotor_part = $helicopter0_model_test2/MovingTailRotorPart
@onready var helicopter_form = $helicopter0_model_test2

@onready var cam_pivot_y = $CamPivotY
@onready var cam_pivot_z = $CamPivotY/CamPivotZ

@onready var hud_collective = $HUD/HBoxContainer/VBoxContainer2/Collective
@onready var hud_cyclic = $HUD/HBoxContainer/VBoxContainer2/Cyclic
@onready var hud_rotor_rpm = $HUD/HBoxContainer/VBoxContainer/RPM
@onready var hud_engine = $HUD/HBoxContainer/VBoxContainer/Engine
@onready var hud_engine_rpm = $HUD/HBoxContainer/VBoxContainer/EngineRPM

@onready var fps_counter = $HUD/FPSCounter

var engine_on = false
var engine_omega = 0.0 # max 282,74 [rad/s] = 2700 rpm
var clutch_engaged = false
var belt_tension = 0.0 #max 1.0 (fraction)

var main_rotor_omega = 55.5 # max 55.50 # angular velocity [rad/s]
var tail_rotor_omega = 0.0 #max 355.62828798 # angular velocity [rad/s]
var rotor_drag = 0.0

var main_rotor_collective_pitch = 0.0
var cyclic = Vector2()

func die():
	get_tree().change_scene_to_file("res://World/world_0.tscn")

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion:
		cam_pivot_y.rotate_y(-event.relative.x * mouse_sensitivity) 
		cam_pivot_z.rotate_z(-event.relative.y * mouse_sensitivity) 
		cam_pivot_z.rotation.z = clamp(cam_pivot_z.rotation.z, -PI/2, PI/2)

func _process(delta):
	#camera control
	cam_pivot_y.global_position = global_position
	
	cam_pivot_y.rotation.y += Input.get_axis("camera_right", "camera_left")  * camera_rotation_speed * delta
	cam_pivot_z.rotation.z += Input.get_axis("camera_down", "camera_up")  * camera_rotation_speed * delta
	cam_pivot_z.rotation.z = clamp(cam_pivot_z.rotation.z, -PI/2, PI/2)
	
	#helicopter control
	if Input.is_action_just_pressed("start_engine"):
		engine_on = !engine_on
	engine_omega = 282.74 * int(engine_on)
	if Input.is_action_just_pressed('engage_clutch'):
		clutch_engaged = true
	belt_tension += delta/10 * int(clutch_engaged)
	belt_tension = clampf(belt_tension, 0.1, 1.0)
	cyclic = Input.get_vector("cyclic_forward", "cyclic_backward", "cyclic_right", "cyclic_left")
	
	main_rotor_collective_pitch += Input.get_axis("collective_pitch_down", "collective_pitch_up") * delta * 15
	main_rotor_collective_pitch = clamp(main_rotor_collective_pitch, main_rotor_collective_min, main_rotor_collective_max)
	
	#visual stuff
	moving_main_rotor_part.quaternion *= Quaternion(Vector3(0.0471064507, 0.99888987496, 0), main_rotor_omega * delta)
	moving_tail_rotor_part.quaternion *= Quaternion(Vector3(0, 0, 1), tail_rotor_omega * delta)
	
	#setting HUD values
	fps_counter.text = str(Engine.get_frames_per_second())
	
	hud_collective.text = 'collective: ' + str(main_rotor_collective_pitch) + ' °'
	hud_cyclic.text = 'cyclic: ' + str(cyclic)
	hud_engine.text = ['engine off', 'engine on'][int(engine_on)]
	hud_rotor_rpm.text = 'rotor rpm: ' + str(main_rotor_omega * 9.549297)
	hud_engine_rpm.text = 'engine rpm: ' + str(engine_omega * 9.549297)

func _physics_process(_delta):
	#kinda working cyclic control by offsetting the position of where the force is being applied along the rotor disc
	#the offset is just made up in terms of how it feels, based on nothing at all
	#cyclic += Vector2(main_rotor_pos_ind.position.x + helicopter_form.position.x, main_rotor_pos_ind.position.z + helicopter_form.position.z)

	var main_rotor_pos = to_global(Vector3(cyclic.x * main_rotor_radius/20 + main_rotor_pos_ind.position.x + helicopter_form.position.x, main_rotor_pos_ind.position.y, cyclic.y * main_rotor_radius/20 + main_rotor_pos_ind.position.z + helicopter_form.position.z)) - global_position
	var tail_rotor_pos = tail_rotor_pos_ind.global_position - global_position
	
	#main_rotor_pos += Vector3(main_rotor_pos_ind.global_position.x-global_position.x, 0, main_rotor_pos_ind.global_position.z-global_position.z)
	$MainRotorThrustVectorInd.global_position = global_position + main_rotor_pos
	
	#0.006 at max collective
	#this is mostly made up, but in such a way that the maximum main rotor thrust is about 8000 N, which some random hp-to-thrust calculator spat at me and i just went with it
	var main_rotor_thrust_coefficient = main_rotor_collective_pitch * 0.0005
	var main_rotor_thrust_force = 0.5 * GlobalScript.air_density * pow(main_rotor_omega * main_rotor_radius, 2) * PI * pow(main_rotor_radius, 2) * main_rotor_thrust_coefficient
	apply_force(transform.basis.y * main_rotor_thrust_force, main_rotor_pos)
	#uhh make this make sense i guess
	apply_torque(transform.basis.y * -92466.8 / 55.5 * (rotor_drag/0.01424075)) # main_rotor_omega)
	
	#drag - good for now ok
	apply_force(-linear_velocity.normalized() * 0.5 * GlobalScript.air_density * pow(linear_velocity.length(), 2) * 0.36 * 6)#drag_coefficient * 5)
	
	print(-linear_velocity.normalized() * 0.5 * GlobalScript.air_density * pow(linear_velocity.length(), 2) * 0.36 * 6)#drag_coefficient * 5)
	
	#set to exactly countertorque the main rotor with some random control values
	var tail_rotor_thrust_coefficient = 92466.8 / 55.5 / (tail_rotor_pos_ind.position.x + helicopter_form.position.x) / -19937.17825851426525086220 + Input.get_axis("antitorque_right", "antitorque_left") * 0.015
	var tail_rotor_thrust_force = 0.5 * 1.225 * pow(tail_rotor_omega * tail_rotor_radius, 2) * PI * pow(tail_rotor_radius, 2) * tail_rotor_thrust_coefficient
	apply_force(transform.basis.z * tail_rotor_thrust_force, tail_rotor_pos)
	
	### rotors rotating
	#
	main_rotor_omega = engine_omega * (55.5/282.74) * belt_tension
	#rotor profile drag; totally made up based on feel
	rotor_drag = 0.005 + main_rotor_collective_pitch * pow(main_rotor_omega, 2) * 0.00000025
	main_rotor_omega -= rotor_drag
	print(rotor_drag)
	
	main_rotor_omega = clamp(main_rotor_omega, 0, 55.5)
	tail_rotor_omega = 355.62828798/55.5 * main_rotor_omega
