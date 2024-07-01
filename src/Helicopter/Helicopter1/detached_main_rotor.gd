extends RigidBody3D

var sound_timer = 0.0

func _process(delta):
	if sound_timer > 1.0/8.0:
		$RotorSound.play()
		print(11)
		sound_timer = 0
	sound_timer += delta
