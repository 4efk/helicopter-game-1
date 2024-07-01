extends Node

var air_density = 1.225

const SETTINGS_FILEPATH = 'user://settings.dat'
const GAMEDATA_FILEPATH = 'user://gamedata.dat'

var fps_options = [30, 60, 120, 144, 240, 360, 0]

var settings = {
	'text_typing_time': 0.0166666,
	'mouse_sensitivity': 0.005,
	'fps': 1,
	'master_volume': 0,
	'music_volume': 0,
	'sfx_volume': 0,
	'vsync':false,
	'show_fps':false,
	'fullscreen':4
}

var game_save = {
	'freeflight_unlocked': false,
}

const DEFAULT_FLIGHTSCHOOL_CHECKPOINT = [0, Vector3(110.5, 15.325, -138.8), Vector3(0, 180, 0), false] # [current_task, player_helicopter.global_position, player_helicopter.global_rotation, helicopter started]

var current_gamemode = 0
var flightschool_checkpoint = DEFAULT_FLIGHTSCHOOL_CHECKPOINT.duplicate()

var unpausable = false

func _ready():
	save_settings()
	load_settings()
	load_game()
	apply_settings()

func _process(delta):
	if Input.is_action_just_pressed("toggle_fullscreen"):
		settings['fullscreen'] = 4 * int(!settings['fullscreen'])
		DisplayServer.window_set_mode(settings['fullscreen'])
		save_settings()

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

func apply_settings():
	if GlobalScript.settings['master_volume'] <= -45:
		AudioServer.set_bus_mute(0, true)
	else:
		AudioServer.set_bus_mute(0, false)
		AudioServer.set_bus_volume_db(0, GlobalScript.settings['master_volume'])
	
	if GlobalScript.settings['sfx_volume'] <= -45:
		AudioServer.set_bus_mute(1, true)
	else:
		AudioServer.set_bus_mute(1, false)
		AudioServer.set_bus_volume_db(1, GlobalScript.settings['sfx_volume'])
	
	if GlobalScript.settings['music_volume'] <= -45:
		AudioServer.set_bus_mute(2, true)
	else:
		AudioServer.set_bus_mute(2, false)
		AudioServer.set_bus_volume_db(2, GlobalScript.settings['music_volume'])
		
	Engine.max_fps = GlobalScript.fps_options[GlobalScript.settings['fps']]
	DisplayServer.window_set_vsync_mode(GlobalScript.settings['vsync'])
	DisplayServer.window_set_mode(GlobalScript.settings['fullscreen'])
