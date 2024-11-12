extends RigidBody3D

# =========================
# Constants
# =========================
const SPEED: float = 100.0              # Speed at which the bullet travels
const MAX_DISTANCE: float = 100.0        # Maximum distance the bullet can travel before being destroyed
const DAMAGE: int = 1                   # Damage inflicted by the bullet upon hitting an enemy

# =========================
# Member Variables
# =========================
var traveled_distance: float = 0.0       # Distance the bullet has traveled since being spawned

# =========================
# Onready Variables
# =========================
@onready var initial_position: Vector3 = global_transform.origin  # Starting position of the bullet

# =========================
# Ready Function
# =========================
func _ready() -> void:
	"""
	Initialize the bullet when the scene is ready.
	Sets the initial linear velocity based on the bullet's forward direction.
	"""
	# Calculate the forward direction based on the bullet's local Z-axis
	var forward_direction: Vector3 = -transform.basis.z.normalized()
	
	# Set the bullet's linear velocity to move forward at the defined SPEED
	linear_velocity = forward_direction * SPEED
	
	# Optionally, disable gravity for the bullet if it should travel in a straight line
	# gravity_scale = 0.0

# =========================
# Physics Process
# =========================
func _physics_process(delta: float) -> void:
	"""
	Handles physics-related updates such as tracking traveled distance and destroying the bullet after exceeding MAX_DISTANCE.
	
	Args:
		delta (float): The frame delta time.
	"""
	# Calculate the distance traveled in this frame
	var distance_traveled: float = linear_velocity.length() * delta
	
	# Increment the total traveled distance
	traveled_distance += distance_traveled
	
	# Check if the bullet has exceeded its maximum travel distance
	if traveled_distance >= MAX_DISTANCE:
		_destroy_bullet()
	
	# Optional: Implement additional logic such as homing behavior or gravity effects
	# Example: Apply additional forces or adjust velocity here

# =========================
# Collision Handling
# =========================
func _on_area_3d_body_entered(body: Node) -> void:
	"""
	Callback function triggered when the bullet enters another body's area.
	Handles interactions such as dealing damage to enemies.
	
	Args:
		body (Node): The body that the bullet has collided with.
	"""
	# Check if the collided body is part of the "enemies" group
	if body.is_in_group("enemies"):
		# Ensure the body has the `take_damage` method before calling it
		if body.has_method("take_damage"):
			body.take_damage(DAMAGE)
		
		# Destroy the bullet upon hitting an enemy
		_destroy_bullet()
	
	# Optionally, handle collisions with other groups (e.g., walls, obstacles)
	# elif body.is_in_group("walls"):
	#     _destroy_bullet()

func _on_area_3d_body_exited(body: Node) -> void:
	"""
	Callback function triggered when the bullet exits another body's area.
	Currently not used but can be implemented for additional behaviors.
	
	Args:
		body (Node): The body that the bullet has exited.
	"""
	pass  # Placeholder for future implementation

# =========================
# Bullet Destruction
# =========================
func _destroy_bullet() -> void:
	"""
	Handles the destruction of the bullet.
	Removes the bullet from the scene and frees its memory.
	"""
	queue_free()

# =========================
# Additional Notes
# =========================
# - Ensure that the bullet node has an Area3D (or CollisionShape3D) set up to detect collisions.
# - The "enemies" group should be defined in the project, and enemy nodes should be added to this group.
# - The `take_damage` method must be implemented in the enemy scripts to handle damage application.
# - Adjust the constants (SPEED, MAX_DISTANCE, DAMAGE) to balance the bullet's behavior as needed.
# - Optionally, add visual and audio effects upon bullet impact for enhanced feedback.
# - Consider implementing a lifetime for the bullet using a Timer node instead of distance tracking if preferred.

# =========================
# Example Usage of Signals
# =========================
# To connect the collision signals, ensure that the bullet's Area3D node emits the `body_entered` and `body_exited` signals.
# This can be done either in the editor or via code in the `_ready` function.

# Example connection via code:
# func _ready() -> void:
#     var area = $Area3D  # Replace with the correct path to your Area3D node
#     area.connect("body_entered", Callable(self, "_on_area_3d_body_entered"))
#     area.connect("body_exited", Callable(self, "_on_area_3d_body_exited"))
#     # Set initial velocity as before
