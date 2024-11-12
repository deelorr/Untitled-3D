extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const RANDOM_MOVE_INTERVAL = 2.0 # Time in seconds before changing direction

var health: int = 5
var random_direction: Vector3 = Vector3.ZERO
var random_move_timer: float = 0.0

func _ready():
	randomize() # Ensure randomness for the random number generator

func _physics_process(delta):
	if health <= 0:
		queue_free()
		print("Enemy defeated")
	
	# Add gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# Random movement logic
	random_move_timer -= delta
	if random_move_timer <= 0.0:
		_change_random_direction()
		random_move_timer = RANDOM_MOVE_INTERVAL
	
	# Apply random movement
	if random_direction != Vector3.ZERO:
		velocity.x = random_direction.x * SPEED
		velocity.z = random_direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

func _on_area_3d_body_entered(_body):
	pass

func _on_area_3d_body_exited(_body):
	pass

func take_damage(amount: int):
	health -= amount
	print("Enemy Health:", health)

func _change_random_direction():
	# Generate a random normalized direction vector on the XZ plane
	random_direction = Vector3(randf() * 2 - 1, 0, randf() * 2 - 1).normalized()
	print("New Random Direction:", random_direction)
