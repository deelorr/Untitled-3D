extends CharacterBody3D

# =========================
# Constants
# =========================
const WALK_SPEED: float = 5.0
const SPRINT_SPEED: float = 8.0
const AIM_SPEED: float = 3.0  # Slower movement when aiming
const JUMP_VELOCITY: float = 4.0
const GRAVITY: float = 8.0
const SENSITIVITY: float = 0.003
const BASE_FOV: float = 75.0
const FOV_CHANGE: float = 1.5
const FOV_CHANGE_SPEED: float = 8.0
const AIM_FOV: float = 40.0  # Field of View when aiming

# Head Bobbing Parameters
const BOB_FREQ: float = 3.0      # Frequency of head bobbing
const BOB_AMP: float = 0.1       # Amplitude of head bobbing

# Shooting Parameters
const SHOOT_DISTANCE: float = 100.0
const FIRE_RATE: float = 0.2      # Time between shots
const SHOOT_DAMAGE: int = 10

# Aiming Constraints
const PITCH_LIMIT: float = 80.0  # Maximum vertical look angle in degrees

# =========================
# Exported Variables
# =========================
@export var camera_list: Array[Camera3D] = []         # List of cameras for switching
@export var rotation_speed: float = 0.005           # Mouse rotation sensitivity

# =========================
# Member Variables
# =========================
var is_aiming: bool = false                          # Is the player currently aiming
var gun_idle_position: Vector3                       # Gun's default position
#var gun_aim_position: Vector3 = Vector3(0, -0.1, -0.25)  # Gun's aiming position
var gun_aim_position: Vector3 = Vector3(0, -0.75, -1)  # Gun's aiming position


var current_camera_index: int = 0                    # Index of the active camera
var speed: float = WALK_SPEED                        # Current movement speed
var head_bob_timer: float = 0.0                      # Timer for head bobbing
var can_shoot: bool = true                            # Can the player shoot
var camera_start_pos: Vector3                         # Initial camera position
var bullet_count: int = 0                             # Number of bullets fired
var current_pitch: float = 0.0                        # Current pitch rotation of the camera

# =========================
# Onready Variables
# =========================
@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var gun: Node3D = $Head/Camera3D/Gun
@onready var bullet_scene: PackedScene = preload("res://scenes/9mm_bullet.tscn")
@onready var bullet_spawn_marker: Marker3D = $Head/Camera3D/Gun/BulletSpawnMarker
@onready var bullet_count_label: Label = $HUD/NinePatchRect/Stats/bullet_count_label

# =========================
# Ready Function
# =========================
func _ready() -> void:
	"""
	Initialize the character when the scene is ready.
	Sets up mouse mode, initial camera position, gun position, and activates the first camera.
	"""
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)  # Capture the mouse within the window
	camera_start_pos = camera.transform.origin        # Store the initial camera position
	gun_idle_position = gun.transform.origin          # Store the gun's idle position
	
	# Activate only the first camera in the list
	for i in range(camera_list.size()):
		camera_list[i].current = (i == current_camera_index)

# =========================
# Input Handling
# =========================
func _input(event):
	"""
	Handle input events such as camera switching and mouse movement for looking around.
	"""
	# Switch camera when the "switch_camera" action is pressed (e.g., Tab key)
	if event.is_action_pressed("switch_camera"):
		switch_camera()
	
	# Handle mouse movement for camera rotation
	if event is InputEventMouseMotion:
		_handle_mouse_motion(event)

func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	"""
	Process mouse motion to rotate the character and the head.
	
	Args:
		event (InputEventMouseMotion): The mouse motion event containing relative movement.
	"""
	# Rotate the character horizontally based on mouse X movement
	rotate_y(-event.relative.x * SENSITIVITY)
	
	# Rotate the head vertically based on mouse Y movement with clamping
	current_pitch -= event.relative.y * SENSITIVITY
	current_pitch = clamp(current_pitch, deg_to_rad(-PITCH_LIMIT), deg_to_rad(PITCH_LIMIT))
	head.rotation.x = current_pitch

# =========================
# Physics Process
# =========================
func _physics_process(delta: float) -> void:
	"""
	Handle physics-related updates such as gravity, movement, head bobbing, FOV, and gun positioning.
	"""
	_apply_gravity(delta)
	_handle_inputs()
	_handle_movement(delta)
	_update_head_bob(delta)
	_update_fov(delta)
	_update_gun_position(delta)
	
	# Apply the calculated velocity to the character
	move_and_slide()
	
	# Update the bullet count display on the HUD
	bullet_count_label.text = str(bullet_count)

# =========================
# Gravity Application
# =========================
func _apply_gravity(delta: float) -> void:
	"""
	Apply gravity to the character if they are not on the floor.
	
	Args:
		delta (float): The frame delta time.
	"""
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

# =========================
# Input Handling for Actions
# =========================
func _handle_inputs() -> void:
	"""
	Process player inputs for shooting, aiming, jumping, sprinting, and quitting the game.
	"""
	# Handle shooting
	if Input.is_action_pressed("shoot"):
		_shoot()
	
	# Handle aiming
	is_aiming = Input.is_action_pressed("aim")
	
	# Handle jumping if the player is on the floor
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	# Handle sprinting: sprint if "sprint" is pressed and not aiming
	if Input.is_action_pressed("sprint") and not is_aiming:
		speed = SPRINT_SPEED
	elif is_aiming:
		speed = AIM_SPEED
	else:
		speed = WALK_SPEED
	
	# Handle quitting the game
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()

# =========================
# Movement Handling
# =========================
func _handle_movement(delta: float) -> void:
	"""
	Calculate and apply the character's movement based on input directions.
	
	Args:
		delta (float): The frame delta time.
	"""
	# Get input vector from movement actions
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	
	# Convert input vector to world direction
	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if is_on_floor():
		if direction.length() > 0:
			# Move the character based on input direction and current speed
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			# Gradually decelerate to zero when no input is provided
			velocity.x = lerp(velocity.x, 0.0, delta * 7.0)
			velocity.z = lerp(velocity.z, 0.0, delta * 7.0)
	else:
		# Apply air control with slower acceleration when in the air
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 3.0)

# =========================
# Head Bobbing
# =========================
func _update_head_bob(delta: float) -> void:
	"""
	Update the camera's position to create a head bobbing effect when the player is moving.
	
	Args:
		delta (float): The frame delta time.
	"""
	if is_on_floor() and velocity.length() > 0 and not is_aiming:
		# Increment the head bob timer based on movement speed
		head_bob_timer += delta * velocity.length()
		
		# Apply head bobbing offset to the camera's position
		camera.transform.origin = camera_start_pos + _calculate_head_bob(head_bob_timer)
	else:
		# Reset the camera to its initial position when not moving, in the air, or aiming
		camera.transform.origin = camera_start_pos

func _calculate_head_bob(time: float) -> Vector3:
	"""
	Calculate the head bobbing offset based on the elapsed time.
	
	Args:
		time (float): The elapsed time for head bobbing.
	
	Returns:
		Vector3: The calculated offset for head bobbing.
	"""
	var offset: Vector3 = Vector3.ZERO
	offset.y = sin(time * BOB_FREQ) * BOB_AMP         # Vertical bobbing
	offset.x = cos(time * BOB_FREQ / 2) * BOB_AMP     # Horizontal bobbing
	return offset

# =========================
# Field of View (FOV) Update
# =========================
func _update_fov(delta: float) -> void:
	"""
	Smoothly update the camera's Field of View (FOV) based on the player's movement and aiming state.
	
	Args:
		delta (float): The frame delta time.
	"""
	var target_fov: float
	
	if is_aiming:
		# Set FOV to aiming value when aiming
		target_fov = AIM_FOV
	else:
		# Adjust FOV based on movement speed to simulate speed effect
		var velocity_clamped: float = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
		target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	
	# Smoothly interpolate the camera's FOV towards the target FOV
	camera.fov = lerp(camera.fov, target_fov, delta * FOV_CHANGE_SPEED)

# =========================
# Gun Position Update
# =========================
func _update_gun_position(delta: float) -> void:
	"""
	Smoothly interpolate the gun's position between idle and aiming positions.
	Applies head bobbing offset when not aiming.
	
	Args:
		delta (float): The frame delta time.
	"""
	var target_position: Vector3
	
	if is_aiming:
		# Target position when aiming
		target_position = gun_aim_position
	else:
		# Target position with head bobbing offset when not aiming
		target_position = gun_idle_position + _calculate_head_bob(head_bob_timer)
	
	# Smoothly interpolate the gun's position towards the target position
	gun.transform.origin = gun.transform.origin.lerp(target_position, delta * 10.0)

# =========================
# Shooting Mechanism
# =========================
func _shoot() -> void:
	"""
	Handle the shooting action by instancing a bullet and applying a cooldown based on FIRE_RATE.
	Increments the bullet count upon successful shooting.
	"""
	if not can_shoot:
		return  # Prevent shooting if in cooldown
	
	can_shoot = false  # Start cooldown
	
	if bullet_scene:
		# Instance the bullet from the preloaded scene
		var bullet = bullet_scene.instantiate() as RigidBody3D
		
		# Set the bullet's global transform to match the spawn marker's transform
		bullet.global_transform = bullet_spawn_marker.global_transform
		
		# Optionally, set the bullet's velocity here if needed
		
		# Add the bullet to the current scene
		get_tree().get_current_scene().add_child(bullet)
	
	# Start the cooldown timer using a deferred call to avoid pausing the game
	var timer = Timer.new()
	timer.wait_time = FIRE_RATE
	timer.one_shot = true
	timer.connect("timeout", Callable(self, "_on_shoot_cooldown_complete"))
	add_child(timer)
	timer.start()
	
	# Increment the bullet count
	bullet_count += 1

func _on_shoot_cooldown_complete() -> void:
	"""
	Callback function called when the shooting cooldown is complete.
	Allows the player to shoot again.
	"""
	can_shoot = true

# =========================
# Camera Switching
# =========================
func switch_camera() -> void:
	"""
	Switch to the next camera in the camera_list. Deactivates the current camera and activates the next one.
	"""
	if camera_list.is_empty():
		return  # No cameras to switch
	
	# Deactivate the current camera
	camera_list[current_camera_index].current = false
	
	# Update the camera index to the next camera, wrapping around if necessary
	current_camera_index = (current_camera_index + 1) % camera_list.size()
	
	# Activate the new current camera
	camera_list[current_camera_index].current = true

# =========================
# Quit Game Functionality
# =========================
# (Handled within _handle_inputs())

# =========================
# Additional Notes
# =========================
# - Ensure that all input actions ("switch_camera", "shoot", "aim", "jump", "sprint", "ui_cancel", "move_left", "move_right", "move_forward", "move_backward")
#   are properly defined in the project's Input Map settings.
# - The `bullet_scene` should be a properly set up RigidBody3D with collision and movement logic.
# - The gun and camera nodes should be correctly positioned within the scene tree for accurate aiming and shooting.
# - Adjust constants like speeds, FOV values, and head bobbing parameters to fit the desired feel of the game.
