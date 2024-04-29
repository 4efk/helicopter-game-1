extends RigidBody

func _physics_process(delta):
	var direction = Vector3(0, 18, 0)
	
	if Input.is_action_pressed("forward"):
		direction.x = 5
	if Input.is_action_pressed("backward"):
		direction.x = -5
	if Input.is_action_pressed("left"):
		direction.z = -5
	if Input.is_action_pressed("right"):
		direction.z = 5
	
	add_central_force(direction)
