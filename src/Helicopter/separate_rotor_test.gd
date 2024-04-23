extends Node

@onready var rotor = $Rotor

func _ready():
	pass

func _physics_process(delta):
	rotor.apply_force(Vector3(0, 4000, 0))
