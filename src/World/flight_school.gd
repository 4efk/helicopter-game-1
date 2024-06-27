extends Node3D

@onready var ui_checklist = $WorldUI/StartupChecklist
@onready var checklist_animation_player = $WorldUI/StartupChecklist/ChecklistAnimationPlayer
@onready var ui_instruction_text = $WorldUI/IntructionMessage/VBoxContainer/InstructionText
@onready var ui_intruction_message = $WorldUI/IntructionMessage
@onready var ui_finish = $WorldUI/FinishUI
@onready var ui_fail = $WorldUI/FailUI

@onready var player_helicopter = $PlayerHelicopter
@onready var ending_camera = $EndingCamera

@onready var fail_timer = $FailTimer

var instruction_messages = [
	[
		"Hey, welcome to this helicopter training. You will learn the skills necessary to safely operate a chopper here",
		"You probably already know about the three main controls used in flight.",
		"The collective controls the pitch of the blades, and therefore the thrust of the main rotor. You keep that in check using [shift]/[L2]/[LT] and [spacebar]/[R2]/[RT].",
		"The cyclic that tells the aircraft where to go with [w], [a], [s], [d], or the left thumbstick",
		"And the anti-torque, which makes the ship turn in a certain direction. You would use the [mouse1]/[L1]/[LB] and [mouse2]/[R1]/[RB] for that.",
		"So let's start her up!",
		"Bring up the startup checklist by pressing [c] or [whatever] and follow it very carefully, otherwise you might damage the engine or transmission",
	], [
		"Nice work! Now we're ready to fly.",
		"Let's land on the second helipad there. First slowly raise the collective to about 8˚, which will increase the rotor's thrust, remember? It should get us off the ground.",
		"Use the cyclic to direct the aircraft forward and when you get to where you wanna land, lower the collective just a bit to slowly descend.",
		"Controlling the bird may seem very difficult at first, but don't worry, you'll get used to it eventually. Just be careful not to slam it into the ground!",
	], [
		"Very well. Now try to fly a little further. I'll let you know when to come back. And don't forget the controls: collective, cyclic, anti-torque.",
	], [
		"That's alright, now land on one of the helipads again."
	], [
		"Good. Now this one's gonna be a bit tricky.",
		"Did you see the tiny island over there? I want you to hover above that lonely palm tree for about thirty seconds.",
		"Get over there when you're ready and I'll time it for you.",
	], [
		"You did it! Good job. Now land again, the next task requires a bit more thorough explanation."
	], [
		"So you need to learn how to land the helicopter when you loose the engine, but don't worry, it's not as hard as it sounds.",
		"The most important thing is lowering the collective immediately after losing power.",
		"After only 3 seconds, the rotor system will lose so much inertia that it won't be possible to land safely. During autorotation, rotor inertia is the most valuable thing you have.",
		"Next thing you do is glide, with the drag coefficient similar to a parachute, the rotor disk will prevent us from falling like a rock.",
		"Then about 6 feet off the ground you're gonna flare the collective back up to cushion the landing.",
		"First autos are rarely ever soft landings, but a good landing is the one you walk away from, haha.",
		"So first gain some altitude, get up to about 500 feet. Also, try to position yourself in front of where you wanna land. Preferably a long flat stretch.",
	], [
		"That's plenty. Now skip this message when you're ready. I'll cut the engine. \n [tab]"
	], [
		"Remember: lower the collective, glide, raise the collective and move your cyclic back before hitting the ground."
	], [
		"Nicely done! That wasn't bad at all for your first time!",
		"In my eyes you've proven yourself worthy of a pilot's license"
	]
]

var tasks = [
	"startup",
	"first flight",
	"second flight",
	"second landing",
	"hover",
	"afterhover landing",
	"autorotation p1",
	"autorotation p2",
	"autorotation p3",
	"last landing",
]

var autorotation_height = 150 # [m]
var longer_flight_distance = 150 # [m]

var current_message = 0
var typing = false
var current_message_character = 0
var typing_timer = 0.0

var assigned_task = false
var current_task = 0
var task_progress = 0

var hovering_timer = 0.0

var checkpoint_pos = Vector3()
var checkpoint_rot = Vector3()
var checkpoint_engine_state = false

var change_ending_camera = true

func type_instruction_text(message_number):
	ui_instruction_text.text = ''
	typing_timer = 0
	current_message = message_number
	current_message_character = 0
	typing = true

func finish_task():
	if current_task == len(instruction_messages)-1:
		print('you won and stuff')
		ui_finish.show()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		GlobalScript.flightschool_checkpoint = GlobalScript.DEFAULT_FLIGHTSCHOOL_CHECKPOINT.duplicate()
		ending_camera.global_position = get_viewport().get_camera_3d().global_position
		ending_camera.global_rotation = get_viewport().get_camera_3d().global_rotation
		ending_camera.current = true
		if !GlobalScript.game_save['freeflight_unlocked']:
			GlobalScript.game_save['freeflight_unlocked'] = true
			GlobalScript.save_game()
		return
	
	# HOVER MIGHT BE A BIT WEIRD HERE 
	# I MEAN IT'S JUST NOT GREAT IF YOU FINISH THE TASK IN THE AIR LOL
	if current_task in [tasks.find('startup'), tasks.find('first flight'), tasks.find('second landing'), tasks.find('autorotation p3'), tasks.find('last landing')]:
		save_checkpoint()
	
	current_task += 1
	task_progress = 0
	
	type_instruction_text(0)

func save_checkpoint():
	checkpoint_pos = player_helicopter.global_position
	checkpoint_rot = player_helicopter.global_rotation_degrees
	checkpoint_engine_state = player_helicopter.engine_on

func player_die():
	if current_task == tasks.find("second landing"):
		current_task = tasks.find("second flight")
	if current_task in [tasks.find('autorotation p2'), tasks.find('autorotation p3')]:
		current_task = tasks.find('autorotation p1')
	#if current_task == tasks.find("last landing"):
		#checkpoint_pos = player_helicopter.global_position
	
	GlobalScript.flightschool_checkpoint = [current_task, checkpoint_pos, checkpoint_rot, checkpoint_engine_state]
	#get_tree().change_scene_to_file("res://World/flight_school.tscn")

func player_fail(dead=false, immediate=false):
	print(1)
	player_die()
	if immediate:
		_on_fail_timer_timeout()
		return
	if fail_timer.is_stopped():
		fail_timer.start()

func _ready():
	type_instruction_text(0)
	assigned_task = true
	current_task = GlobalScript.flightschool_checkpoint[0]
	player_helicopter.global_position = GlobalScript.flightschool_checkpoint[1]
	checkpoint_pos = GlobalScript.flightschool_checkpoint[1]
	player_helicopter.global_rotation_degrees =  GlobalScript.flightschool_checkpoint[2]
	checkpoint_rot = GlobalScript.flightschool_checkpoint[2]
	checkpoint_engine_state = GlobalScript.flightschool_checkpoint[3]
	#current_task = 6

func _process(delta):
	#print((player_helicopter.global_position - $Helipad2.global_position).length())
	
	if Input.is_action_just_pressed("show_extra_ui"):
		#ui_checklist.visible = !ui_checklist.visible
		if !checklist_animation_player.is_playing():
			checklist_animation_player.play(["hide_checklist", "show_checklist"][int(!ui_checklist.visible)])
		
	#print(current_task, current_message)
	#print(hovering_timer)
	
	# instruction typing and skipping
	#print(typing_timer)
	if typing and typing_timer > GlobalScript.settings['text_typing_time'] and current_message_character < len(instruction_messages[current_task][current_message]):
		ui_instruction_text.text += instruction_messages[current_task][current_message][current_message_character]
		typing_timer = 0.0
		current_message_character += 1
		if current_task == tasks.find("last landing") and current_message == 1 and current_message_character == len(instruction_messages[current_task][current_message])-1:
			finish_task()
	elif typing and current_message_character >= len(instruction_messages[current_task][current_message]):
		typing = false
		if current_message < len(instruction_messages[current_task])-1:
			ui_instruction_text.text += '\n [tab]'
	elif typing:
		typing_timer += delta
	
	if Input.is_action_just_pressed("ui_focus_next") and !typing and current_message < len(instruction_messages[current_task])-1:
		current_message += 1
		type_instruction_text(current_message)
	
	# task finishing logic
	if current_task == tasks.find('startup') and player_helicopter.main_rotor_omega == 55.5:
		finish_task()
	
	if current_task == tasks.find('second flight') and player_helicopter.global_position.length() > longer_flight_distance:
		finish_task()
	
	if current_task == tasks.find('autorotation p1') and player_helicopter.global_position.y > autorotation_height:
		finish_task()
	if current_task == tasks.find('autorotation p2') and player_helicopter.global_position.y < autorotation_height:
		current_task = tasks.find('autorotation p1')
		task_progress = 0
	
		type_instruction_text(len(instruction_messages[current_task])-1)
	if current_task == tasks.find('autorotation p2') and Input.is_action_just_pressed("ui_focus_next"):
		finish_task()
		player_helicopter.engine_working = false
		player_helicopter.engine_on = false
	if current_task == tasks.find('autorotation p3') and player_helicopter.global_position.y < 2 and player_helicopter.linear_velocity.length() < 0.005:
		finish_task()
		#player_helicopter.engine_working = true
	
	if task_progress:
		if current_task in [tasks.find('first flight'), tasks.find('second landing'), tasks.find('last landing'), tasks.find('afterhover landing')] and player_helicopter.linear_velocity.length() < 0.005:
			finish_task()
		if current_task == tasks.find('hover'):
			hovering_timer += delta
			print(hovering_timer)
		if current_task == tasks.find('hover') and hovering_timer > 30:
			finish_task()

func _on_helipad_body_entered(body):
	if body.is_in_group('helicopter') and assigned_task and current_task == tasks.find('first flight'):
		task_progress = 1
	if body.is_in_group('helicopter') and assigned_task and current_task == tasks.find('second landing'):
		task_progress = 1
	if body.is_in_group('helicopter') and assigned_task and current_task == tasks.find('last landing'):
		task_progress = 1
	if body.is_in_group('helicopter') and assigned_task and current_task == tasks.find('afterhover landing'):
		task_progress = 1
func _on_helipad_body_exited(body):
	if body.is_in_group('helicopter') and assigned_task and current_task == tasks.find('first flight'):
		task_progress = 0
	if body.is_in_group('helicopter') and assigned_task and current_task == tasks.find('second landing'):
		task_progress = 0
	if body.is_in_group('helicopter') and assigned_task and current_task == tasks.find('last landing'):
		task_progress = 0
	if body.is_in_group('helicopter') and assigned_task and current_task == tasks.find('afterhover landing'):
		task_progress = 0

func _on_helipad_2_body_entered(body):
	if body.is_in_group('helicopter') and assigned_task and current_task == tasks.find('second landing'):
		task_progress = 1
	if body.is_in_group('helicopter') and assigned_task and current_task == tasks.find('last landing'):
		task_progress = 1
	if body.is_in_group('helicopter') and assigned_task and current_task == tasks.find('afterhover landing'):
		task_progress = 1
func _on_helipad_2_body_exited(body):
	if body.is_in_group('helicopter') and assigned_task and current_task == tasks.find('second landing'):
		task_progress = 0
	if body.is_in_group('helicopter') and assigned_task and current_task == tasks.find('last landing'):
		task_progress = 0
	if body.is_in_group('helicopter') and assigned_task and current_task == tasks.find('afterhover landing'):
		task_progress = 0

func _on_hover_area_body_entered(body):
	if body.is_in_group('helicopter') and assigned_task and current_task == tasks.find('hover'):
		task_progress = 1
func _on_hover_area_body_exited(body):
	if body.is_in_group('helicopter') and assigned_task and current_task == tasks.find('hover'):
		task_progress = 0
		hovering_timer = 0

func _on_fail_timer_timeout():
	ui_fail.show()
	ui_intruction_message.hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if change_ending_camera:
		ending_camera.global_position = get_viewport().get_camera_3d().global_position
		ending_camera.global_rotation = get_viewport().get_camera_3d().global_rotation
		player_helicopter.camera.current = false
		ending_camera.current = true

func _on_main_menu_button_pressed():
	get_tree().change_scene_to_file("res://MainMenu/main_menu.tscn")
func _on_retry_button_pressed():
	get_tree().change_scene_to_file("res://World/flight_school.tscn")
