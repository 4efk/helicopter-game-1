extends Node

var air_density = 1.225

var settings = {
	'text_typing_time': 0.0166666
}

const DEFAULT_FLIGHTSCHOOL_CHECKPOINT = [0, Vector3(110.5, 15.325, -138.8), Vector3(0, 180, 0), true] # [current_task, player_helicopter.global_position, player_helicopter.global_rotation, helicopter started]

var current_gamemode = 0
var flightschool_checkpoint = DEFAULT_FLIGHTSCHOOL_CHECKPOINT.duplicate()
