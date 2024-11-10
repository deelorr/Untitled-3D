extends CharacterBody3D

const WALK_SPEED: float = 5.0
const SPRINT_SPEED: float = 8.0
const JUMP_VELOCITY: float = 5.0
const GRAVITY: float = 7.0
const SENSITIVITY: float = 0.005
const BASE_FOV: float = 75.0
const FOV_CHANGE: float = 1.5
const BOB_FREQ: float = 2.4
const BOB_AMP: float = 0.08
const SHOOT_DISTANCE: float = 100.0
const SHOOT_DAMAGE: int = 10
const FIRE_RATE: float = 0.1

var speed: float = WALK_SPEED
var t_bob: float = 0.0
var can_shoot: bool = true
var camera_base_pos: Vector3

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var gun: Node3D = $Head/Camera3D/Gun
@onready var bullet_scene: PackedScene = preload("res://9mm_bullet.tscn")
@onready var bullet_spawn_marker: Marker3D = $Head/Camera3D/Gun/BulletSpawnMarker

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	camera_base_pos = camera.transform.origin
	if not can_shoot:
		return
	can_shoot = false
	# Instance the bullet
	if bullet_scene:
		var bullet = bullet_scene.instantiate() as RigidBody3D
		# Set bullet transform to match the bullet_spawn_marker
		bullet.global_transform = bullet_spawn_marker.global_transform
		# Add bullet to the scene
		get_tree().get_current_scene().add_child.call_deferred(bullet)
	# Start cooldown
	await get_tree().create_timer(FIRE_RATE).timeout
	can_shoot = true
	print("Shot fired")

func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_handle_inputs()
	_handle_movement(delta)
	_update_head_bob(delta)
	_update_fov(delta)
	
	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_handle_mouse_motion(event)

func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	# Rotate the head horizontally
	head.rotate_y(deg_to_rad(-event.relative.x * SENSITIVITY * 100))  # Convert sensitivity to radians
	# Rotate the camera vertically
	camera.rotate_x(deg_to_rad(-event.relative.y * SENSITIVITY * 100))
	# Clamp the camera's vertical rotation to prevent flipping
	camera.rotation_degrees.x = clamp(camera.rotation_degrees.x, -40, 60)

func _shoot() -> void:
	if not can_shoot:
		return
	can_shoot = false
	# Instance the bullet
	if bullet_scene:
		var bullet = bullet_scene.instantiate() as RigidBody3D
		# Set bullet transform to match the bullet_spawn_marker
		bullet.global_transform = bullet_spawn_marker.global_transform
		# Add bullet to the scene
		get_tree().get_current_scene().add_child(bullet)
	# Start cooldown
	await get_tree().create_timer(FIRE_RATE).timeout
	can_shoot = true
	print("Shot fired")

# Apply gravity to the character
func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

# Handle various player inputs
func _handle_inputs() -> void:
	# Quit game
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()
	
	# Shooting
	if Input.is_action_just_pressed("shoot"):
		_shoot()
	
	# Jumping
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	# Sprinting
	speed = SPRINT_SPEED if Input.is_action_pressed("sprint") else WALK_SPEED

# Handle character movement based on input
func _handle_movement(delta: float) -> void:
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction: Vector3 = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if is_on_floor():
		if direction.length() > 0:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			# Gradually decelerate to 0 when no input
			velocity.x = lerp(velocity.x, 0.0, delta * 7.0)
			velocity.z = lerp(velocity.z, 0.0, delta * 7.0)
	else:
		# Apply air control with slower acceleration
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 3.0)

# Update camera position for head bobbing effect
func _update_head_bob(delta: float) -> void:
	if is_on_floor() and velocity.length() > 0:
		t_bob += delta * velocity.length()
		camera.transform.origin = camera_base_pos + _calculate_head_bob(t_bob)
	else:
		# Reset head bobbing when not moving or in air
		camera.transform.origin = camera_base_pos

# Update camera FOV based on movement speed
func _update_fov(delta: float) -> void:
	var velocity_clamped: float = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
	var target_fov: float = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)

# Calculate head bob offset based on time
func _calculate_head_bob(time: float) -> Vector3:
	var pos: Vector3 = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos
