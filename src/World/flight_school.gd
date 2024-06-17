extends Node3D

@onready var ui_checklist = $WorldUI/ChecklistText
@onready var ui_instruction_text = $WorldUI/VBoxContainer/InstructionText
@onready var ui_finish = $WorldUI/FinishUI

@onready var player_helicopter = $PlayerHelicopter

var instruction_messages = [
	[
		"welcome to the helicopte training... whatever",
		"you're gonna learn the basics of how to fly a helicopter",
		"starting with the basic 3 controls:",
		"there's cyclic",
		"collective",
		"antitorque",
		"-----",
		"let's start the helicopter",
		"bring up a startup checklist by pressing [c] and follow it carefully",
	], [
		"now slowly raise collective",
		"and like udunno land on the closest helipad there"
	], [
		"great job bro",
		"now take it a bit further"
	], [
		"return and land"
	], [
		"awesome",
		"next fly over there to that thing and try to hover in the air for 30 seconds"
	], [
		"alright, now for autorotation",
		"explanation",
		"explanation....",
		"so first gain some altitude, get to about ... or so",
	], [
		"okay so now skip this message when you're ready to cut the power \n [tab]"
	], [
		"glide and then quickly raise the collective before hitting the ground"
	], [
		"good",
		"now idk that's it ig just land on a helipad again; engine on"
	]
]

var tasks = [
	"startup",
	"first flight",
	"second flight",
	"second landing",
	"hover",
	"autorotation p1",
	"autorotation p2",
	"autorotation p3",
	"last landing",
]

var autorotation_height = 150 # [m]
var longer_flight_distance = 100 # [m]

var current_message = 0
var typing = false
var current_message_character = 0
var typing_timer = 0.0

var assigned_task = false
var current_task = 0
var task_progress = 0

var hovering_timer = 0.0

var checkpoint_pos = Vector3()

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
		GlobalScript.flightschool_checkpoint = [0, Vector3(0, 1.199, 0)]
		return
		
	current_task += 1
	task_progress = 0
	
	type_instruction_text(0)

func player_die():
	if current_task == tasks.find("second landing"):
		current_task = tasks.find("second flight")
	if current_task in [tasks.find('autorotation p2'), tasks.find('autorotation p3')]:
		current_task = tasks.find('autorotation p1')
	#if current_task == tasks.find("last landing"):
		#checkpoint_pos = player_helicopter.global_position
	
	GlobalScript.flightschool_checkpoint = [current_task, checkpoint_pos]
	get_tree().change_scene_to_file("res://World/flight_school.tscn")
	
func _ready():
	type_instruction_text(0)
	assigned_task = true
	current_task = GlobalScript.flightschool_checkpoint[0]
	player_helicopter.global_position = GlobalScript.flightschool_checkpoint[1]
	checkpoint_pos = GlobalScript.flightschool_checkpoint[1]
	#current_task = 6

func _process(delta):
	
	if Input.is_action_just_pressed("show_extra_ui"):
		ui_checklist.visible = !ui_checklist.visible
	
	#print(current_task, current_message)
	#print(hovering_timer)
	
	# instruction typing and skipping
	if typing and typing_timer > GlobalScript.settings['text_typing_time'] and current_message_character < len(instruction_messages[current_task][current_message]):
		ui_instruction_text.text += instruction_messages[current_task][current_message][current_message_character]
		typing_timer = 0.0
		current_message_character += 1
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
		player_helicopter.engine_working = true
		checkpoint_pos = player_helicopter.global_position
	
	if task_progress:
		if current_task in [tasks.find('first flight'), tasks.find('second landing'), tasks.find('last landing')] and player_helicopter.linear_velocity.length() < 0.005:
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
func _on_helipad_body_exited(body):
	if body.is_in_group('helicopter') and assigned_task and current_task == tasks.find('first flight'):
		task_progress = 0
	if body.is_in_group('helicopter') and assigned_task and current_task == tasks.find('second landing'):
		task_progress = 0
	if body.is_in_group('helicopter') and assigned_task and current_task == tasks.find('last landing'):
		task_progress = 0

func _on_helipad_2_body_entered(body):
	if body.is_in_group('helicopter') and assigned_task and current_task == tasks.find('second landing'):
		task_progress = 1
	if body.is_in_group('helicopter') and assigned_task and current_task == tasks.find('last landing'):
		task_progress = 1
func _on_helipad_2_body_exited(body):
	if body.is_in_group('helicopter') and assigned_task and current_task == tasks.find('second landing'):
		task_progress = 0
	if body.is_in_group('helicopter') and assigned_task and current_task == tasks.find('last landing'):
		task_progress = 0


func _on_hover_area_body_entered(body):
	if body.is_in_group('helicopter') and assigned_task and current_task == tasks.find('hover'):
		task_progress = 1
func _on_hover_area_body_exited(body):
	if body.is_in_group('helicopter') and assigned_task and current_task == tasks.find('hover'):
		task_progress = 0
		hovering_timer = 0
