extends Node3D

var piece_follow_camera = preload("res://Helicopter/Helicopter1/explosion_follow_camera.tscn")

@onready var pieces = $Pieces
@onready var explosion_particles = $ExplosionParticles

func _ready():
	randomize()

func explode(main_rotor_omega, tail_rotor_omega):
	pieces.visible = true
	explosion_particles.emitting = true
	var piece_follow_camera_instance = piece_follow_camera.instantiate()
	#pieces.get_child(randi() % (pieces.get_child_count() - 1)).add_child(piece_follow_camera_instance)
	pieces.add_child(piece_follow_camera_instance)
	#piece_follow_camera.look_at_position = global_position
	for piece in pieces.get_children():
		piece.process_mode = Node.PROCESS_MODE_INHERIT
		piece.freeze = false
		piece.linear_velocity = Vector3(randf_range(-30, 30), randf_range(10, 30), randf_range(-30, 30))
