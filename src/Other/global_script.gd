extends Node

var air_density = 1.225

const SETTINGS_FILEPATH = 'user://settings.dat'
const GAMEDATA_FILEPATH = 'user://gamedata.dat'

var settings = {
	'text_typing_time': 0.0166666
}

var game_save = {
	'freeflight_unlocked': false,
}

const DEFAULT_FLIGHTSCHOOL_CHECKPOINT = [3, Vector3(110.5, 15.325, -138.8), Vector3(0, 180, 0), true] # [current_task, player_helicopter.global_position, player_helicopter.global_rotation, helicopter started]

var current_gamemode = 0
var flightschool_checkpoint = DEFAULT_FLIGHTSCHOOL_CHECKPOINT.duplicate()

func _ready():
	load_settings()
	load_game()

func save_game():
	var error = FileAccess.open(GAMEDATA_FILEPATH, FileAccess.WRITE)
	error.store_var(game_save)
	error.close()

func load_game():
	if FileAccess.file_exists(GAMEDATA_FILEPATH):
		var error = FileAccess.open(GAMEDATA_FILEPATH, FileAccess.READ)
		if error:
			game_save = error.get_var()
			error.close()

func save_settings():
	var error = FileAccess.open(SETTINGS_FILEPATH, FileAccess.WRITE)
	error.store_var(settings)
	error.close()

func load_settings():
	if FileAccess.file_exists(SETTINGS_FILEPATH):
		var error = FileAccess.open(SETTINGS_FILEPATH, FileAccess.READ)
		if error:
			settings = error.get_var()
			error.close()
