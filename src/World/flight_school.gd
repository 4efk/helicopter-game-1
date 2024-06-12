extends Node3D

@onready var ui_checklist = $WorldUI/ChecklistText
@onready var ui_instruction_text = $WorldUI/VBoxContainer/InstructionText

@onready var player_helicopter = $Helicopter0_1

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
		"great job bro"
	]
]

var tasks = [
	"startup",
	"first flight",
]

var current_message = 0
var typing = false
var current_message_character = 0
var typing_timer = 0.0

var assigned_task = false
var current_task = 0
var task_progress = 0

func type_instruction_text(message_number):
	ui_instruction_text.text = ''
	typing_timer = 0
	current_message = message_number
	current_message_character = 0
	typing = true

func finish_task():
	if current_task == len(instruction_messages)-1:
		print('you won and stuff')
		return
		
	current_task += 1
	task_progress = 0
	
	type_instruction_text(0)
	
func _ready():
	type_instruction_text(0)
	assigned_task = true
	print(tasks.find('first flight'))

func _process(delta):
	if Input.is_action_just_pressed("show_extra_ui"):
		ui_checklist.visible = !ui_checklist.visible
	
	print(current_task, current_message)
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
	
	if task_progress:
		if current_task == tasks.find('first flight') and player_helicopter.linear_velocity.length() < 0.005:
			finish_task()

func _on_helipad_body_entered(body):
	if body.is_in_group('helicopter') and assigned_task and current_task == tasks.find('first flight'):
		task_progress = 1
func _on_helipad_body_exited(body):
	if body.is_in_group('helicopter') and assigned_task and current_task == tasks.find('first flight'):
		task_progress = 0
