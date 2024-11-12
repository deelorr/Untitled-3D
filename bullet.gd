extends RigidBody3D

const SPEED: float = 50.0
var damage: int = 10

func _ready():
	# Set the initial linear velocity based on the bullet's forward direction
	linear_velocity = transform.basis.z * SPEED

func _process(_delta: float):
	#destroy the bullet after some time
	if global_transform.origin.distance_to(Vector3.ZERO) > 100:
		queue_free()

func _on_area_3d_body_entered(body):
	if body.is_in_group("enemies"):
		body.take_damage(1)

func _on_area_3d_body_exited(_body):
	pass
