extends RigidBody3D

@export var main_rotor_radius = 3.835 # radius of the main rotor disc [m]
@export var main_rotor_blades_n = 2
@export var main_rotor_thrust_coefficient = 0.0
@export var main_rotor_collective_max = 12 # max/min angle of main rotor blades [°]; made up
@export var main_rotor_collective_min = -4

@export var tail_rotor_radius = 0.0

@export var drag_coefficient = 0.36

@export var camera_rotation_speed = 2

@onready var main_rotor_pos_ind = $MainRotorPosInd
@onready var tail_rotor_pos_ind = $TailRotorPosInd

@onready var cam_pivot_y = $CamPivotY
@onready var cam_pivot_z = $CamPivotY/CamPivotZ

@onready var hook = $Rope/HookArea

@onready var hud_collective = $HUD/HBoxContainer/Collective
@onready var hud_cyclic = $HUD/HBoxContainer/Cyclic

@onready var fps_counter = $HUD/FPSCounter

var main_rotor_omega =  55.50 # angular velocity [rad/s]

var main_rotor_collective_pitch = 0.0
var cyclic = Vector2()

var hooked_object = null

func die():
	get_tree().change_scene_to_file("res://World/world_0.tscn")

func _ready():
	pass

func _process(delta):
	#camera control
	cam_pivot_y.global_position = global_position
	
	cam_pivot_y.rotation.y += Input.get_axis("camera_right", "camera_left")  * camera_rotation_speed * delta
	cam_pivot_z.rotation.z += Input.get_axis("camera_down", "camera_up")  * camera_rotation_speed * delta
	cam_pivot_z.rotation.z = clamp(cam_pivot_z.rotation.z, -PI/2, PI/2)
	
	if Input.is_action_just_pressed("start_engine"):
		main_rotor_omega = 55.50
	if Input.is_action_just_pressed("stop_engine"):
		main_rotor_omega = 0
	
	cyclic = Input.get_vector("cyclic_forward", "cyclic_backward", "cyclic_right", "cyclic_left")
	
	main_rotor_collective_pitch += Input.get_axis("collective_pitch_down", "collective_pitch_up") * delta * 15
	main_rotor_collective_pitch = clamp(main_rotor_collective_pitch, main_rotor_collective_min, main_rotor_collective_max)
	
	if Input.is_action_just_pressed("unhook_object") and hooked_object:
		hooked_object.freeze = false
		hooked_object.linear_velocity = linear_velocity
		hooked_object = null
	
	#setting HUD values
	fps_counter.text = str(Engine.get_frames_per_second())
	
	hud_collective.text = 'collective: ' + str(main_rotor_collective_pitch) + ' °'
	hud_cyclic.text = 'cyclic: ' + str(cyclic)
	
func _physics_process(_delta):
	#kinda working cyclic control by offsetting the position of where the force is being applied along the rotor disc
	#TODO TWEAK THE CYCLIC SENSITIVITY PREFERABLY BASED ON SOME REAL DATA
	var main_rotor_pos = to_global(Vector3(cyclic.x * main_rotor_radius/30, main_rotor_pos_ind.position.y, cyclic.y * main_rotor_radius/30)) - global_position
	var tail_rotor_pos = tail_rotor_pos_ind.global_position - global_position
	
	main_rotor_thrust_coefficient = main_rotor_collective_pitch * 0.001
	var main_rotor_thrust_force = 0.5 * GlobalScript.air_density * pow(main_rotor_omega * main_rotor_radius, 2) * PI * pow(main_rotor_radius, 2) * main_rotor_thrust_coefficient
	
	print(main_rotor_thrust_force)
	#main_rotor_thrust_force = 000
	
	apply_force(transform.basis.y * main_rotor_thrust_force, main_rotor_pos)
	#TODO ALSO BASE THE FORCE ON SOME REAL DATA
	apply_torque(transform.basis.y * -256.45)
	
	apply_force(-linear_velocity.normalized() * 0.5 * GlobalScript.air_density * pow(linear_velocity.length(), 2) * drag_coefficient * 5)
	
	print(linear_velocity)
	
	#TODO tweak this userealdataandrealforces too
	#currently this is set to exactly countertorque the main rotor (-256.45/-4.727 = ~54.25216839433044214089)
	#the rest is random
	var tail_rotor_thrust_force = 54.25 + Input.get_axis("antitorque_right", "antitorque_left") * 80#2523.46
	apply_force(transform.basis.z * tail_rotor_thrust_force, tail_rotor_pos)
	
	#different visual markers
	$markers/MeshInstance3D.global_position = global_position + tail_rotor_pos
	$markers/MainRotorThrustMarker.global_position = global_position + main_rotor_pos
	$markers/MeshInstance3D/RayCast3D.target_position = transform.basis.z * tail_rotor_thrust_force * .02
	
	#hooked object logic
	if hooked_object:
		hooked_object.global_position = hook.global_position

#main rotor collision (bad for a helicopter)
func _on_main_rotor_area_body_entered(body):
	die()

func _on_hook_area_body_entered(body):
	if body.is_in_group('pickable') and !hooked_object:
		body.freeze = true
		hooked_object = body

