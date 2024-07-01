extends RigidBody3D

var detached_main_rotor = preload("res://Helicopter/Helicopter1/detached_main_rotor.tscn")
var detached_tail_rotor = preload("res://Helicopter/Helicopter1/detached_tail_rotor.tscn")

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
@export var default_camera_rotation = Vector3(0, PI, -PI/6)
@export var camera_recover_speed = 1

@onready var main_rotor_pos_ind = $helicopter1_model_2/MainRotorPosInd
@onready var tail_rotor_pos_ind = $helicopter1_model_2/TailRotorPosInd
@onready var engine_cooldown_timer = $EngineCooldownTimer
@onready var engine_start_timer = $EngineStartTimer

@onready var moving_main_rotor_part = $helicopter1_model_2/MovingMainRotorPart
@onready var moving_tail_rotor_part = $helicopter1_model_2/MovingTailRotorPart
@onready var helicopter_form = $helicopter1_model_2
@onready var hook = $Hook
@onready var helicopter_exploded = $Helicopter_1_0_Exploded

@onready var cam_pivot_y = $CamPivotY
@onready var cam_pivot_z = $CamPivotY/CamPivotZ
@onready var cam_spring_arm = $CamPivotY/CamPivotZ/CameraSpringArm
@onready var camera = $CamPivotY/CamPivotZ/CameraSpringArm/Camera3D
@onready var camera_reset_timer = $CameraResetTimer

@onready var hud = $HUD
@onready var hud_collective = $HUD/InstrumentPanel/CollectiveBase
@onready var hud_cyclic = $HUD/HBoxContainer/VBoxContainer2/Cyclic
@onready var hud_antitorque = $HUD/HBoxContainer/VBoxContainer2/TailRotorCollective
@onready var hud_rpm = $HUD/InstrumentPanel/RPMBase
@onready var hud_rotor_rpm = $HUD/HBoxContainer/VBoxContainer/RPM
@onready var hud_engine = $HUD/HBoxContainer/VBoxContainer/Engine
@onready var hud_engine_rpm = $HUD/HBoxContainer/VBoxContainer/EngineRPM
@onready var hud_clutch = $HUD/HBoxContainer/VBoxContainer/Clutch
@onready var hud_altitude = $HUD/InstrumentPanel/AltimeterBase
@onready var hud_light_engine = $HUD/InstrumentPanel/EngineLight
@onready var hud_light_clutch = $HUD/InstrumentPanel/ClutchLight
@onready var hud_light_clutch_moving = $HUD/InstrumentPanel/ClutchMovingLight
@onready var hud_light_low_rpm = $HUD/InstrumentPanel/LowRPMLight

@onready var fps_counter = $HUD/FPSCounter

@onready var engine_startup_sound = $EngineStartup
@onready var engine_startup_fail_sound = $EngineStartupFail
@onready var engine_run_sound = $EngineRun
@onready var engine_shutoff_sound = $EngineShutoff
@onready var explosion_sound = $Explosion
@onready var water_splash_sound = $WaterSplash
@onready var rotor_sound = $Rotor
@onready var main_rotor_break_sound = $MainRotorBreak
@onready var tail_rotor_break_sound = $TailRotorBreak
@onready var bg_music = $BGMusic
@onready var clutch_switch_sound = $ClutchSwitch

var dead = false

var engine_working = true
var engine_on = false
var engine_cooled = true
var engine_alpha = 0.0 # [rad/s^2]
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

var rotor_sound_timer = 0.0
var rotor_sound_frequency = 0

func die(immediate=false, explode=true):
	if dead:
		return
	#get_tree().change_scene_to_file("res://World/world_0.tscn")
	engine_run_sound.stop()
	engine_shutoff_sound.play()
	if explode:
		disable_collision()
		helicopter_form.hide()
		helicopter_exploded.explode(main_rotor_omega, tail_rotor_omega)
		explosion_sound.play()
		engine_run_sound.stop()
		engine_shutoff_sound.stop()
	dead = true
	hud.hide()
	if main_rotor_broken or tail_rotor_broken:
		return
	if GlobalScript.current_gamemode == 1:
		get_parent().player_die()
	elif GlobalScript.current_gamemode == 0:
		get_parent().player_fail(true, immediate)
		#get_parent().change_ending_camera = !explode

func rotor_broken(rotor, fling_direction=Vector3.UP):
	var broken_before = main_rotor_broken or tail_rotor_broken
	if rotor == 0 and !main_rotor_broken:
		main_rotor_broken = true
		moving_main_rotor_part.hide()
		var detached_main_rotor_instance = detached_main_rotor.instantiate()
		add_child(detached_main_rotor_instance)
		var detached_main_rotor_child = get_child(get_child_count()-1)
		detached_main_rotor_child.global_position = main_rotor_pos_ind.global_position + transform.basis.y * 1
		detached_main_rotor_child.linear_velocity = fling_direction * randf_range(30, 50)
		detached_main_rotor_child.angular_velocity = transform.basis.y * main_rotor_omega
		main_rotor_break_sound.play()
	elif rotor == 1 and !tail_rotor_broken:
		tail_rotor_broken = true
		moving_tail_rotor_part.hide()
		var detached_tail_rotor_instance = detached_tail_rotor.instantiate()
		add_child(detached_tail_rotor_instance)
		var detached_tail_rotor_child = get_child(get_child_count()-1)
		detached_tail_rotor_child.global_position = tail_rotor_pos_ind.global_position + transform.basis.z * -1
		detached_tail_rotor_child.linear_velocity = fling_direction * randf_range(40, 50)
		detached_tail_rotor_child.angular_velocity = transform.basis.z * tail_rotor_omega
		tail_rotor_break_sound.play()
	if GlobalScript.current_gamemode == 0 and !broken_before:
		get_parent().player_fail()
		hud.hide()
	if GlobalScript.current_gamemode == 1 and !broken_before:
		get_parent().player_die()
		hud.hide()

func disable_collision():
	$"@CollisionShape3D@25131".set_deferred("disabled", true)
	$"@CollisionShape3D@25130".set_deferred("disabled", true)
	$"@CollisionShape3D@25129".set_deferred("disabled", true)
	$"@CollisionShape3D@25128".set_deferred("disabled", true)
	$"@CollisionShape3D@25127".set_deferred("disabled", true)
	$"@CollisionShape3D@25126".set_deferred("disabled", true)


func _ready():
	mouse_sensitivity = GlobalScript.settings['mouse_sensitivity']
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	cam_spring_arm.add_excluded_object(self)
	cam_pivot_y.rotation.y = default_camera_rotation.y
	cam_pivot_z.rotation.z = default_camera_rotation.z
	
	#print(engine_power_curve.sample(1))
	main_rotor_prev_pos = main_rotor_pos_ind.global_position
	
	if GlobalScript.flightschool_checkpoint[3]:
		engine_on = true
		main_rotor_omega = 55.5
		engine_omega = 282.74
		clutch_engaged = true
		belt_tension = 1.0

func _input(event):
	if event is InputEventMouseMotion:
		cam_pivot_y.rotate_y(-event.relative.x * mouse_sensitivity) 
		cam_pivot_z.rotate_z(-event.relative.y * mouse_sensitivity) 
		cam_pivot_z.rotation.z = clamp(cam_pivot_z.rotation.z, -PI/2, PI/2)
		player_moving_camera = true
		camera_reset_timer.start()

func _process(delta):
	$extra_water_1.global_position = global_position
	$extra_water_1.global_position.y =  10
	
	#SFX
	if engine_on and engine_working and !dead:
		if !engine_run_sound.playing and !engine_startup_sound.playing and !engine_startup_fail_sound.playing: engine_run_sound.play()
	
	rotor_sound_frequency = main_rotor_omega / PI # (1.5 * PI)
	if rotor_sound_frequency > 9.0: rotor_sound_frequency = 9.0
	if rotor_sound_frequency > 0.5:
		if rotor_sound_timer >= 1 / rotor_sound_frequency and !main_rotor_broken and !dead:
			rotor_sound.pitch_scale = randf_range(.9, 1.0)
			rotor_sound.volume_db = main_rotor_omega / 55.5 * 10.0
			rotor_sound.play()
			rotor_sound_timer = 0.0
	rotor_sound_timer += delta
	
	if !bg_music.playing and !dead and !main_rotor_broken and !tail_rotor_broken:
		bg_music.play()
	
	#camera control
	cam_pivot_y.global_position = global_position
	
	if !player_moving_camera and linear_velocity.length() > 1 and !Input.get_vector("camera_up", "camera_down", "camera_right", "camera_left"):
		cam_pivot_y.quaternion = cam_pivot_y.quaternion.slerp(quaternion, camera_recover_speed * delta)
		cam_pivot_z.quaternion = cam_pivot_z.quaternion.slerp(Quaternion.from_euler(default_camera_rotation), camera_recover_speed * delta)

		cam_pivot_y.rotation.z = 0
		cam_pivot_y.rotation.x = 0
		cam_pivot_z.rotation.y = 0
		cam_pivot_z.rotation.x = 0
	
	cam_pivot_y.rotation.y += Input.get_axis("camera_right", "camera_left") * camera_rotation_speed * delta
	cam_pivot_z.rotation.z += Input.get_axis("camera_down", "camera_up") * camera_rotation_speed * delta
	cam_pivot_z.rotation.z = clamp(cam_pivot_z.rotation.z, -PI/2, PI/2)
	
	#helicopter control
	if Input.is_action_just_pressed("start_engine") and engine_cooled and !engine_startup_fail_sound.playing and !engine_startup_sound.playing:
		engine_on = !engine_on
		engine_cooled = false
		engine_cooldown_timer.start()
		if !engine_on:
			engine_run_sound.stop()
			engine_shutoff_sound.play()
			return
		if engine_omega < 130 and main_rotor_omega < 10 and belt_tension > 0.5:
			engine_on = false
			main_rotor_omega += 0.05
			engine_startup_fail_sound.play()
		else:
			engine_on = false
			engine_start_timer.start()
			engine_startup_sound.play()
	engine_on = bool(int(engine_on) * int(engine_working))
	if engine_on:
		engine_alpha = [141.37, 282.7433/8][int(engine_omega > 141.37)]
	else:
		engine_alpha = -282.7433 / 6
	
	engine_omega += engine_alpha * delta
	engine_omega = clampf(engine_omega, 0, 282.7433)
	
	#if engine_on and engine_omega < 130 and engine_omega > (530/2700 * main_rotor_omega) and belt_tension > 0.5:
		#engine_on = false
		#main_rotor_omega += 0.05
	
	if Input.is_action_just_pressed('engage_clutch') and !clutch_switch_sound.playing:
		clutch_engaged = !clutch_engaged
		clutch_movement = [-1.0, 1][int(clutch_engaged)]
		clutch_switch_sound.play()
		
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
	
	hud_rpm.get_node("EnginePointer").rotation_degrees = 50 - (81.5 * engine_omega / 282.7433) # 50 - -31.5 °  81.5
	hud_rpm.get_node("RotorPointer").rotation_degrees = -50 + (81.5 * main_rotor_omega / 55.5) # 50 - -31.5 °  81.5
	hud_altitude.get_child(0).rotation_degrees = clamp(global_position.y * 3.28084 / 975 * 334, 0, 334)
	hud_collective.get_child(0).rotation_degrees = main_rotor_collective_pitch / main_rotor_collective_max * 334
	hud_light_engine.get_child(0).visible = engine_on and engine_working
	hud_light_clutch.get_child(0).visible = belt_tension == 1.0
	hud_light_clutch_moving.get_child(0).visible = not belt_tension in [0.05, 1.0]
	hud_light_low_rpm.get_child(0).visible = main_rotor_omega > 10 and main_rotor_omega < 45
	
	#hud_cyclic.text = 'cyclic: ' + str(cyclic)
	#hud_engine.text = ['engine off', 'engine on'][int(engine_on)]
	#hud_clutch.text = ['clutch disengaged', 'clutch engaged'][int(clutch_engaged)]
	#hud_rotor_rpm.text = 'rotor rpm: ' + str(main_rotor_omega * 9.549297)
	#hud_engine_rpm.text = 'engine rpm: ' + str(engine_omega * 9.549297)
	#hud_altitude.text = 'altitude: ' + str(int(global_position.y * 3.28084)) + ' ft'

func _physics_process(_delta):
	#falling into water
	if global_position.y < 0 and !dead:
		die(true, false)
		water_splash_sound.play()
	#kinda working cyclic control by offsetting the position of where the force is being applied along the rotor disc
	#the offset is just made up in terms of how it feels, based on nothing at all
	#cyclic += Vector2(main_rotor_pos_ind.position.x + helicopter_form.position.x, main_rotor_pos_ind.position.z + helicopter_form.position.z)

	var main_rotor_pos = to_global(Vector3(cyclic.x * main_rotor_radius/30 + main_rotor_pos_ind.position.x + helicopter_form.position.x, main_rotor_pos_ind.position.y, cyclic.y * main_rotor_radius/30 + main_rotor_pos_ind.position.z + helicopter_form.position.z)) - global_position
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
	if engine_omega > (530/2700 * main_rotor_omega):
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
	if normal_relative_velocity.length() > 4:
		die()
	#if !state.get_contact_count(): return
	#if state.get_contact_impulse(0).length() > 1500:
		#die()

func _on_hook_area_body_entered(body):
	if body.is_in_group('pickable') and !hooked_object:
		body.freeze = true
		hooked_object = body

func _on_main_rotor_disc_area_body_entered(body):
	rotor_broken(0, (global_position - body.global_position).normalized())
func _on_tail_rotor_disc_area_body_entered(body):
	rotor_broken(1,  (global_position - body.global_position).normalized())

func _on_body_entered(body):
	#print(1)
	#print(get_inverse_inertia_tensor())
	pass

func _on_engine_cooldown_timer_timeout():
	engine_cooled = true

func _on_camera_reset_timer_timeout():
	player_moving_camera = false

func _on_engine_start_timer_timeout():
	engine_on = true
