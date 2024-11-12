extends CharacterBody3D

# =========================
# Constants
# =========================
const SPEED: float = 5.0                        # Movement speed of the enemy
const JUMP_VELOCITY: float = 4.5                # Velocity applied when the enemy jumps
const RANDOM_MOVE_INTERVAL: float = 2.0         # Time in seconds before changing direction

# =========================
# Exported Variables
# (None in this script, but can be added if needed)
# =========================

# =========================
# Member Variables
# =========================
var health: int = 5                              # Health points of the enemy
var random_direction: Vector3 = Vector3.ZERO     # Current random movement direction
var random_move_timer: float = 0.0               # Timer to track when to change direction

# =========================
# Ready Function
# =========================
func _ready() -> void:
	"""
	Initialize the enemy when the scene is ready.
	Seeds the random number generator to ensure varied behavior.
	"""
	randomize()  # Seed the random number generator for true randomness

# =========================
# Physics Process
# =========================
func _physics_process(delta: float) -> void:
	"""
	Handles physics-related updates such as movement, gravity, and health checks.
	
	Args:
		delta (float): The frame delta time.
	"""
	# Check if the enemy's health has dropped to zero or below
	if health <= 0:
		_defeat_enemy()
		return  # Exit early since the enemy is defeated
	
	# Apply gravity if the enemy is not on the floor
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# Handle random movement logic
	_handle_random_movement(delta)
	
	# Apply the calculated velocity to the enemy
	move_and_slide()

# =========================
# Random Movement Handling
# =========================
func _handle_random_movement(delta: float) -> void:
	"""
	Manages the timing and direction of the enemy's random movements.
	
	Args:
		delta (float): The frame delta time.
	"""
	# Decrement the movement timer by the elapsed time
	random_move_timer -= delta
	
	# Check if it's time to change direction
	if random_move_timer <= 0.0:
		_change_random_direction()
		random_move_timer = RANDOM_MOVE_INTERVAL  # Reset the timer
	
	# Apply movement based on the current random direction
	if random_direction != Vector3.ZERO:
		# Move in the random direction at the defined speed
		velocity.x = random_direction.x * SPEED
		velocity.z = random_direction.z * SPEED
	else:
		# Gradually slow down if there's no movement direction
		velocity.x = move_toward(velocity.x, 0.0, SPEED * delta)
		velocity.z = move_toward(velocity.z, 0.0, SPEED * delta)

# =========================
# Enemy Defeat Handling
# =========================
func _defeat_enemy() -> void:
	"""
	Handles the logic when the enemy is defeated.
	Frees the enemy from the scene and prints a defeat message.
	"""
	print("Enemy defeated")
	queue_free()  # Remove the enemy from the scene

# =========================
# Damage Handling
# =========================
func take_damage(amount: int) -> void:
	"""
	Reduces the enemy's health by the specified damage amount.
	
	Args:
		amount (int): The amount of damage to apply.
	"""
	health -= amount
	print("Enemy Health:", health)
	
	# Optionally, trigger defeat logic if health drops to zero
	if health <= 0:
		_defeat_enemy()

# =========================
# Random Direction Change
# =========================
func _change_random_direction() -> void:
	"""
	Generates a new random normalized direction vector on the XZ plane.
	Ensures that the enemy moves in varied directions over time.
	"""
	# Generate random values between -1 and 1 for X and Z axes
	var random_x: float = randf_range(-1.0, 1.0)
	var random_z: float = randf_range(-1.0, 1.0)
	
	# Create the new random direction vector and normalize it
	random_direction = Vector3(random_x, 0.0, random_z).normalized()
	
	# Debug print to track direction changes
	print("New Random Direction:", random_direction)

# =========================
# Collision Handling
# =========================
func _on_area_3d_body_entered(body: Node) -> void:
	"""
	Callback function triggered when another body enters the enemy's area.
	Can be used to handle interactions like detecting the player or projectiles.
	
	Args:
		body (Node): The body that entered the area.
	"""
	# Example: If the body is a player or a projectile, handle accordingly
	if body.is_in_group("Player"):
		# Implement logic when the player enters the area
		pass
	elif body.is_in_group("Projectile"):
		# Optionally, take damage when hit by a projectile
		take_damage(body.damage_amount)
		body.queue_free()  # Remove the projectile after collision

func _on_area_3d_body_exited(body: Node) -> void:
	"""
	Callback function triggered when another body exits the enemy's area.
	Can be used to handle logic when interactions end.
	
	Args:
		body (Node): The body that exited the area.
	"""
	# Example: Stop tracking the body or reset states
	pass

# =========================
# Additional Notes
# =========================
# - Ensure that the enemy node has an Area3D node with collision shapes to detect body entries and exits.
# - The groups "Player" and "Projectile" should be defined in the project to categorize different types of bodies.
# - The `take_damage` function can be expanded to include animations, sounds, or other effects upon taking damage.
# - Adjust the constants like SPEED, JUMP_VELOCITY, and RANDOM_MOVE_INTERVAL to fine-tune the enemy's behavior.
# - Consider adding more behaviors such as chasing the player, attacking, or patrolling for a more dynamic enemy.
