extends RigidBody3D

@export var main_rotor_radius = 3.835 # radius of the main rotor disc [m]
@export var main_rotor_blades_n = 2
@export var main_rotor_collective_max = 12 # max/min angle of main rotor blades [°]; kinda made up
@export var main_rotor_collective_min = 0

@export var tail_rotor_radius = 0.535
@export var tail_rotor_collective_max = 12 # max/min angle of tail rotor blades [°]; kinda extracted from the airfoil AOA/lift coefficient graph
@export var tail_rotor_collective_min = -10

@export var drag_coefficient = 0.36

@export var engine_power_curve = Curve.new()

@export var camera_rotation_speed = 2
@export var mouse_sensitivity = 0.005

@onready var main_rotor_pos_ind = $helicopter1_model_2/MainRotorPosInd
@onready var tail_rotor_pos_ind = $helicopter1_model_2/TailRotorPosInd

@onready var moving_main_rotor_part = $helicopter1_model_2/MovingMainRotorPart
@onready var moving_tail_rotor_part = $helicopter1_model_2/MovingTailRotorPart
@onready var helicopter_fuselage = $helicopter1_model_2
@onready var hook = $Hook

@onready var cam_pivot_y = $CamPivotY
@onready var cam_pivot_z = $CamPivotY/CamPivotZ
@onready var cam_spring_arm = $CamPivotY/CamPivotZ/CameraSpringArm
@onready var camera = $CamPivotY/CamPivotZ/CameraSpringArm/Camera3D

@onready var hud_collective = $HUD/HBoxContainer/VBoxContainer2/Collective
@onready var hud_cyclic = $HUD/HBoxContainer/VBoxContainer2/Cyclic
@onready var hud_antitorque = $HUD/HBoxContainer/VBoxContainer2/TailRotorCollective
@onready var hud_rotor_rpm = $HUD/HBoxContainer/VBoxContainer/RPM
@onready var hud_engine = $HUD/HBoxContainer/VBoxContainer/Engine
@onready var hud_engine_rpm = $HUD/HBoxContainer/VBoxContainer/EngineRPM
@onready var hud_clutch = $HUD/HBoxContainer/VBoxContainer/Clutch
@onready var hud_altitude = $HUD/HBoxContainer/VBoxContainer2/Altitude

@onready var fps_counter = $HUD/FPSCounter

var dead = false

var engine_working = true
var engine_on = false
var engine_omega = 0.0 # max 282.74 [rad/s] = 2700 rpm
var engine_throttle = 0.25
var clutch_engaged = false
var belt_tension = 0.05 #max 1.0 (fraction)
var clutch_movement = 0

var main_rotor_omega = 0.0 # max 55.50 # angular velocity [rad/s]
var tail_rotor_omega = 0.0 #max 355.62828798 # angular velocity [rad/s]
var rotor_drag = 0.0
var main_rotor_alpha = 0.0 # [rad/s^2]
var main_rotor_induced_torque = 0.0
var main_rotor_prev_pos = Vector3()
var main_rotor_broken = false
var tail_rotor_broken = false

var main_rotor_collective_pitch = 0.0
var tail_rotor_collective_pitch = 0.0
var cyclic = Vector2()

var hooked_object = null

var player_moving_camera = false

func die(immediate=false):
	#get_tree().change_scene_to_file("res://World/world_0.tscn")
	dead = true
	if GlobalScript.current_gamemode == 1:
		get_parent().player_die()
	elif GlobalScript.current_gamemode == 0:
		get_parent().player_fail(true, immediate)

func rotor_broken(rotor):
	if rotor == 0:
		main_rotor_broken = true
	elif rotor == 1:
		tail_rotor_broken = true
	if GlobalScript.current_gamemode == 0:
		get_parent().player_fail()

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	cam_spring_arm.add_excluded_object(self)
	
	#print(engine_power_curve.sample(1))
	main_rotor_prev_pos = main_rotor_pos_ind.global_position
	
	if GlobalScript.flightschool_checkpoint[3]:
		engine_on = true
		main_rotor_omega = 55.5
		#engine_omega = 282.74
		clutch_engaged = true
		belt_tension = 1.0

func _input(event):
	player_moving_camera = false
	if event is InputEventMouseMotion:
		cam_pivot_y.rotate_y(-event.relative.x * mouse_sensitivity) 
		cam_pivot_z.rotate_z(-event.relative.y * mouse_sensitivity) 
		cam_pivot_z.rotation.z = clamp(cam_pivot_z.rotation.z, -PI/2, PI/2)
		player_moving_camera = true

func _process(delta):
	#camera control
	
	cam_pivot_y.global_position = global_position
	
	#cam_pivot_y.global_position = cam_pivot_y.global_position.lerp(global_position, delta * 10)
	
	#cam_pivot_y.rotation.y += Input.get_axis("camera_right", "camera_left") * camera_rotation_speed * delta
	#if !player_moving_camera:
		#cam_pivot_y.quaternion = cam_pivot_y.quaternion.slerp(quaternion, delta * 5)
		#cam_pivot_y.rotation.z = 0
		#cam_pivot_y.rotation.x = 0
	
	cam_pivot_z.rotation.z += Input.get_axis("camera_down", "camera_up") * camera_rotation_speed * delta
	cam_pivot_z.rotation.z = clamp(cam_pivot_z.rotation.z, -PI/2, PI/2)
	
	#helicopter control
	if Input.is_action_just_pressed("start_engine"):
		engine_on = !engine_on
	engine_on = bool(int(engine_on) * int(engine_working))
	
	var engine_alpha = 282.7433/(engine_omega+10.0) + 4
	print(engine_alpha)
	
	engine_omega += engine_alpha
	#engine_omega = 282.74 * int(engine_on)
	engine_omega = clampf(engine_omega, 0, 282.7433)
	
	if Input.is_action_just_pressed('engage_clutch'):
		print(1)
		clutch_engaged = !clutch_engaged
		clutch_movement = [-1.0/3.0, 1][int(clutch_engaged)]
		
	print(clutch_movement)
	belt_tension += delta/10 * clutch_movement
	belt_tension = clampf(belt_tension, 0.05, 1.0)
	#if belt_tension == 1.0 or belt_tension == 0.05:
		#clutch_movement = 0
	
	cyclic = Input.get_vector("cyclic_forward", "cyclic_backward", "cyclic_right", "cyclic_left")
	
	main_rotor_collective_pitch += Input.get_axis("collective_pitch_down", "collective_pitch_up") * delta * 15
	main_rotor_collective_pitch = clamp(main_rotor_collective_pitch, main_rotor_collective_min, main_rotor_collective_max)
	
	tail_rotor_collective_pitch += Input.get_axis("antitorque_right", "antitorque_left") * delta * 20
	tail_rotor_collective_pitch = clamp(tail_rotor_collective_pitch, tail_rotor_collective_min, tail_rotor_collective_max)
	
	if Input.is_action_just_pressed("unhook_object") and hooked_object:
		hooked_object.freeze = false
		hooked_object.linear_velocity = linear_velocity
		hooked_object = null
	if hooked_object:
		hooked_object.global_position = hook.global_position
	
	#visual stuff
	moving_main_rotor_part.quaternion *= Quaternion(Vector3(0.0471064507, 0.99888987496, 0), main_rotor_omega * delta)
	moving_tail_rotor_part.quaternion *= Quaternion(Vector3(0, 0, 1), tail_rotor_omega * delta)
	
	#setting HUD values
	fps_counter.text = str(Engine.get_frames_per_second())
	
	hud_collective.text = 'collective: ' + str(main_rotor_collective_pitch) + ' °'
	hud_antitorque.text = 'tr collective: ' + str(tail_rotor_collective_pitch) + ' °'
	hud_cyclic.text = 'cyclic: ' + str(cyclic)
	hud_engine.text = ['engine off', 'engine on'][int(engine_on)]
	hud_clutch.text = ['clutch disengaged', 'clutch engaged'][int(clutch_engaged)]
	hud_rotor_rpm.text = 'rotor rpm: ' + str(main_rotor_omega * 9.549297)
	hud_engine_rpm.text = 'engine rpm: ' + str(engine_omega * 9.549297)
	hud_altitude.text = 'altitude: ' + str(int(global_position.y * 3.28084)) + ' ft'

func _physics_process(_delta):
	#falling into water
	if global_position.y < 0 and !dead:
		die(true)
	#kinda working cyclic control by offsetting the position of where the force is being applied along the rotor disc
	#the offset is just made up in terms of how it feels, based on nothing at all
	#cyclic += Vector2(main_rotor_pos_ind.position.x + helicopter_form.position.x, main_rotor_pos_ind.position.z + helicopter_form.position.z)

	var main_rotor_pos = to_global(Vector3(cyclic.x * main_rotor_radius/30 + main_rotor_pos_ind.position.x + helicopter_fuselage.position.x, main_rotor_pos_ind.position.y, cyclic.y * main_rotor_radius/30 + main_rotor_pos_ind.position.z + helicopter_fuselage.position.z)) - global_position
	var tail_rotor_pos = tail_rotor_pos_ind.global_position - global_position
	
	#main_rotor_pos += Vector3(main_rotor_pos_ind.global_position.x-global_position.x, 0, main_rotor_pos_ind.global_position.z-global_position.z)
	$MainRotorThrustVectorInd.global_position = global_position + main_rotor_pos
	
	#0.006 at max collective
	#this is mostly made up, but in such a way that the maximum main rotor thrust is about 8000 N, which some random hp-to-thrust calculator spat at me and i just went with it
	var main_rotor_thrust_coefficient = main_rotor_collective_pitch * 0.0005
	var main_rotor_thrust_force = 0.5 * GlobalScript.air_density * pow(main_rotor_omega * main_rotor_radius, 2) * PI * pow(main_rotor_radius, 2) * main_rotor_thrust_coefficient
	#print(main_rotor_thrust_force)
	main_rotor_thrust_force *= int(!main_rotor_broken)
	main_rotor_thrust_force += 1
	apply_force(transform.basis.y * main_rotor_thrust_force, main_rotor_pos)
	#uhh make this make sense i guess
	#var main_rotor_induced_torque = -(main_rotor_alpha * 0.5 * 2 * 12 * pow(main_rotor_radius, 2) + rotor_drag)
	apply_torque(transform.basis.y * main_rotor_induced_torque) # main_rotor_omega)
	#print(main_rotor_induced_torque)
	
	#fuselage drag - good for now ok
	apply_force(-linear_velocity.normalized() * 0.5 * GlobalScript.air_density * pow(linear_velocity.length(), 2) * drag_coefficient * 6)#drag_coefficient * 5)
	#drag of the rotor disc
	var rotor_disc_relative_vertical_velocity = transform.basis.y.normalized() * linear_velocity / linear_velocity.length()
	rotor_disc_relative_vertical_velocity = (main_rotor_pos_ind.global_position - main_rotor_prev_pos) * 60
	var rotor_disc_drag_coefficient = 4 / pow(((linear_velocity * transform.basis.y).length() / sqrt(main_rotor_thrust_force / (2 * GlobalScript.air_density * PI * pow(main_rotor_radius, 2)))), 2)
	
	#rotor_disc_relative_vertical_velocity = Vector3(0.001, 0.001, 0.001)
	#print(linear_velocity)
	if linear_velocity.length() > 0.001:
		#rotor_disc_relative_vertical_velocity = (transform.basis.y.dot(linear_velocity) / pow(linear_velocity.length(), 2) * transform.basis.y)
		rotor_disc_relative_vertical_velocity = transform.basis.y * (linear_velocity.dot(transform.basis.y) / pow(transform.basis.y.length(), 2))
		#print(linear_velocity)
		#print(rotor_disc_relative_vertical_velocity)
	else:
		rotor_disc_relative_vertical_velocity = Vector3(0, 0, 0)
	
	#print(rotor_disc_relative_vertical_velocity)
	var rotor_disc_drag = 0.5 * GlobalScript.air_density * pow(rotor_disc_relative_vertical_velocity.length(), 2) * PI * pow(main_rotor_radius, 2) * 1.20
	$RotorDiscDragIndicator.global_position = main_rotor_pos_ind.global_position
	#$RotorDiscDragIndicator.global_position = global_position
	#$RotorDiscDragIndicator.target_position = transform.basis.y * 1000
	#$RotorDiscDragIndicator.target_position = transform.basis.y.dot(linear_velocity) / pow(linear_velocity.length(), 2) * transform.basis.y
	$RotorDiscDragIndicator.target_position = rotor_disc_relative_vertical_velocity * 100
	#$RotorDiscDragIndicator.target_position = rotor_disc_relative_vertical_velocity * 1000
	#$RotorDiscDragIndicator.target_position = rotor_disc_relative_vertical_velocity * transform.basis.y# / linear_velocity.length()
	
	#print(rotor_disc_relative_vertical_velocity)
	#print((transform.basis.y.dot(linear_velocity) / pow(linear_velocity.length(), 2) * transform.basis.y).normalized() * rotor_disc_drag)
	#print(Vector3.UP * linear_velocity / linear_velocity.length())
	#print(Vector3(0, 1, 0) * Vector3(5, 1, 1.5) / Vector3(5, 1, 1.5).length())
	#print(Vector3(0, 1, 1) * linear_velocity / linear_velocity.length())
	
	#print(-rotor_disc_relative_vertical_velocity.normalized() * rotor_disc_drag)
	
	# rotor disc drag
	rotor_disc_drag *= int(!main_rotor_broken)
	apply_force(-rotor_disc_relative_vertical_velocity.normalized() * rotor_disc_drag, main_rotor_pos_ind.global_position - global_position)
	
	#print(-rotor_disc_relative_vertical_velocity.normalized() * rotor_disc_drag)
	#print(rotor_disc_relative_vertical_velocity)
	
	main_rotor_prev_pos = main_rotor_pos_ind.global_position
	
	#print(-linear_velocity.normalized() * 0.5 * GlobalScript.air_density * pow(linear_velocity.length(), 2) * drag_coefficient * 6)#drag_coefficient * 5)
	
	#set to exactly countertorque the main rotor at half collective
	var tail_rotor_thrust_coefficient = 0.03 * tail_rotor_collective_pitch / tail_rotor_collective_max
	var tail_rotor_thrust_force = 0.5 * 1.225 * pow(tail_rotor_omega * tail_rotor_radius, 2) * PI * pow(tail_rotor_radius, 2) * tail_rotor_thrust_coefficient
	
	tail_rotor_thrust_force = main_rotor_induced_torque / -(tail_rotor_pos_ind.global_position-global_position).length() + 0.5 * 1.225 * pow(tail_rotor_omega * tail_rotor_radius, 2) * PI * pow(tail_rotor_radius, 2) * 0.01 * Input.get_axis("antitorque_right", "antitorque_left")
	#print(tail_rotor_pos_ind.position.x)
	#print(tail_rotor_thrust_force)
	#print((main_rotor_alpha * 0.5 * 2 * 12 * pow(main_rotor_radius, 2) + rotor_drag))
	tail_rotor_thrust_force *= int(!tail_rotor_broken)
	apply_force(transform.basis.z * tail_rotor_thrust_force, tail_rotor_pos)
	#print((tail_rotor_pos_ind.global_position-global_position).length())
	
	#print(tail_rotor_thrust_coefficient)
	
	### rotors rotating
	#
	var main_rotor_inertia = 0.5 * 2 * 12 * pow(main_rotor_radius, 2)
	main_rotor_alpha = 0.0
	if engine_omega > 0:
		main_rotor_alpha = engine_power_curve.sample(engine_omega/282.74) * 745.7 / engine_omega * (282.7433 / 55.5) / main_rotor_inertia * int(engine_on)
		#print(engine_power_curve.sample(engine_omega/282.74) * 745.7 / engine_omega * (282.7433 / 55.5) / main_rotor_inertia * 0.5 * 2 * 12 * pow(main_rotor_radius, 2))
	
	main_rotor_omega += main_rotor_alpha / 60 * belt_tension
	
	main_rotor_induced_torque = main_rotor_alpha * main_rotor_inertia
	#rotor profile drag; this will apply some torque somehow ok
	
	#rotor_drag = 0.005 + main_rotor_collective_pitch * pow(main_rotor_omega, 2) * 0.00000025
	
	#rotor_drag = drag + friction
	rotor_drag = 2 * 0.5 * 1.225 * pow(main_rotor_radius / 1.5 * main_rotor_omega, 2) * (0.04 * main_rotor_collective_pitch/12 + 0.005) * 0.2014 + 0.02 * 24 * 9.81
	main_rotor_alpha = rotor_drag * main_rotor_radius/2 / main_rotor_inertia
	
	main_rotor_omega -= main_rotor_alpha / 60
	
	main_rotor_induced_torque += main_rotor_alpha * main_rotor_inertia
	main_rotor_induced_torque = -main_rotor_induced_torque
	
	rotor_drag = rotor_drag * main_rotor_radius/2
	
	main_rotor_omega = clamp(main_rotor_omega, 0, 55.5)
	tail_rotor_omega = 355.62828798/55.5 * main_rotor_omega

func _integrate_forces(state):
	var normal_relative_velocity = Vector3(0, 0, 0)
	if linear_velocity.length() > 0.001 and state.get_contact_count():
		var collision_normal = state.get_contact_local_normal(0)
		normal_relative_velocity = collision_normal * (linear_velocity.dot(collision_normal) / pow(collision_normal.length(), 2))
	if normal_relative_velocity.length() > 5:
		die()
	#if !state.get_contact_count(): return
	#if state.get_contact_impulse(0).length() > 1500:
		#die()

func _on_hook_area_body_entered(body):
	if body.is_in_group('pickable') and !hooked_object:
		body.freeze = true
		hooked_object = body

func _on_main_rotor_disc_area_body_entered(body):
	rotor_broken(0)
func _on_tail_rotor_disc_area_body_entered(body):
	rotor_broken(1)

func _on_body_entered(body):
	#print(1)
	#print(get_inverse_inertia_tensor())
	pass
