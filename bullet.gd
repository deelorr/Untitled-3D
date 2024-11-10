extends RigidBody3D

# Speed of the bullet
const SPEED: float = 50.0

# Damage dealt by the bullet
var damage: int = 10

func _ready():
	# Set the initial linear velocity based on the bullet's forward direction
	linear_velocity = transform.basis.z * SPEED

func _process(_delta: float):
	# Optionally, destroy the bullet after some time
	if global_transform.origin.distance_to(Vector3.ZERO) > 100:  # Example limit
		queue_free()

func _on_collision(body: Object):
	# Handle collision logic (e.g., deal damage)
	if body and body.has_method("apply_damage"):
		body.apply_damage(damage)
	queue_free()
