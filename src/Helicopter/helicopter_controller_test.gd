extends RigidBody3D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func _physics_process(delta):
	var cyclic = Input.get_vector('cyclic_backward', 'cyclic_forward', 'cyclic_left', 'cyclic_right')
	
	$MainRotor.position = Vector3(cyclic.x, .5, cyclic.y)

	apply_force(transform.basis.y * 5, $MainRotor.global_position)
	
	$RayCast3D.target_position = global_transform.basis.y.normalized()
	
	
	print(transform.basis.y)
