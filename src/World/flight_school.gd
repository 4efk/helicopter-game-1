extends Node3D

@onready var ui_checklist = $WorldUI/ChecklistText
@onready var ui_instruction_text = $WorldUI/VBoxContainer/InstructionText

@onready var player_helicopter = $Helicopter0_1

var instruction_messages = [
	"welcome to the helicopte training... whatever",
	"you're gonna learn the basics of how to fly a helicopter",
	"starting with the basic 3 controls:",
	"there's cyclic",
	"collective",
	"antitorque",
	"-----", 
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
	print(1)
	if current_task == 0:
		print('you won and stuff')
func _ready():
	type_instruction_text(2)
	assigned_task = true

func _process(delta):
	if Input.is_action_just_pressed("show_extra_ui"):
		ui_checklist.visible = !ui_checklist.visible
		
	if typing and typing_timer > GlobalScript.settings['text_typing_time'] and current_message_character < len(instruction_messages[current_message]):
		ui_instruction_text.text += instruction_messages[current_message][current_message_character]
		typing_timer = 0.0
		current_message_character += 1
	elif current_message_character >= len(instruction_messages[current_message]):
		typing = false
	else:
		typing_timer += delta
	
	if Input.is_action_just_pressed("ui_focus_next"):
		type_instruction_text(5)
		
	if !task_progress: return
	if current_task == 0 and player_helicopter.linear_velocity.length() < 0.005:
		task_progress = 0
		finish_task()

func _on_helipad_body_entered(body):
	if body.is_in_group('helicopter') and assigned_task and current_task == 0:
		task_progress = 1
func _on_helipad_body_exited(body):
	if body.is_in_group('helicopter') and assigned_task and current_task == 0:
		task_progress = 0
