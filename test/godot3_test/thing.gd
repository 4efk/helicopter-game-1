extends RigidBody

func _physics_process(delta):
	add_central_force(Vector3(0, 17, 0))
