extends CharacterBody3D

const WALK_SPEED: float = 5.0
const SPRINT_SPEED: float = 8.0
const JUMP_VELOCITY: float = 4.0
const GRAVITY: float = 8.0
const SENSITIVITY: float = 0.003
const BASE_FOV: float = 75.0
const FOV_CHANGE: float = 1.5
const BOB_FREQ: float = 3 #2.4
const BOB_AMP: float =  0.1 #0.08
const SHOOT_DISTANCE: float = 100.0
const FIRE_RATE: float = 0.2
const SHOOT_DAMAGE: int = 10

# New variables for aiming
var is_aiming: bool = false
var gun_idle_position: Vector3
var gun_aim_position: Vector3 = Vector3(0, -0.1, -0.25)  # Adjust as needed

@export var camera_list: Array[Camera3D] = []
@export var rotation_speed: float = 0.005  # Adjust sensitivity
@export var pitch_limit: float = 80.0  # Limit pitch rotation

var current_camera_index: int = 0
var speed: float = WALK_SPEED
var head_bob_timer: float = 0.0
var can_shoot: bool = true
var camera_start_pos: Vector3
var bullet_count: int = 0
var current_pitch: float = 0.0  # Track the camera's pitch

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var gun: Node3D = $Head/Camera3D/Gun
@onready var bullet_scene: PackedScene = preload("res://9mm_bullet.tscn")
@onready var bullet_spawn_marker: Marker3D = $Head/Camera3D/Gun/BulletSpawnMarker
@onready var bullet_count_label: Label = $HUD/Stats/bullet_count_label

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED) #keeps mouse in screen during play
	camera_start_pos = camera.transform.origin #sets cameras home location
	# Deactivate all cameras except the first one
	for i in range(camera_list.size()):
		camera_list[i].current = (i == current_camera_index)

func switch_camera():
	# Deactivate current camera
	camera_list[current_camera_index].current = false

	# Update the camera index
	current_camera_index = (current_camera_index + 1) % camera_list.size()

	# Activate the new camera
	camera_list[current_camera_index].current = true

func _input(event):
	# Switch camera on a key press (e.g., Tab)
	if event.is_action_pressed("switch_camera"):
		switch_camera()
	
	# Mouse motion event
	if event is InputEventMouseMotion:
		# Horizontal rotation (Y-axis)
		rotate_y(-event.relative.x * SENSITIVITY)
		
		# Vertical rotation (X-axis)
		current_pitch -= event.relative.y * SENSITIVITY
		current_pitch = clamp(current_pitch, deg_to_rad(-pitch_limit), deg_to_rad(pitch_limit))
		head.rotation.x = current_pitch

func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_handle_inputs()
	_handle_movement(delta)
	_update_head_bob(delta)
	_update_fov(delta)
	move_and_slide()
	bullet_count_label.text = str(bullet_count)

#func _unhandled_input(event: InputEvent) -> void:
	#if event is InputEventMouseMotion:
		#_handle_mouse_motion(event)
#
#func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	## Rotate the head horizontally
	#head.rotate_y(deg_to_rad(-event.relative.x * SENSITIVITY * 100))
	## Rotate the camera vertically
	#camera.rotate_x(deg_to_rad(-event.relative.y * SENSITIVITY * 100))
	## Clamp the camera's vertical rotation to prevent flipping
	#camera.rotation_degrees.x = clamp(camera.rotation_degrees.x, -80, 80)

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
	bullet_count += 1

# Apply gravity to the character
func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

# Handle various player inputs
func _handle_inputs() -> void:
	
	# Shooting
	if Input.is_action_pressed("shoot"):
		_shoot()
		
	# Jumping
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	# Sprinting
	if Input.is_action_pressed("sprint"):
		speed = SPRINT_SPEED
	else:
		speed = WALK_SPEED
		
	# Quit game
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()

# Handle character movement based on input
func _handle_movement(delta: float) -> void:
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
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

func _update_head_bob(delta: float) -> void:
	if is_on_floor() and velocity.length() > 0:
		head_bob_timer += delta * velocity.length()
		var bob_offset = _calculate_head_bob(head_bob_timer)
		camera.transform.origin = camera_start_pos + bob_offset
	else:
		# Reset head bobbing when not moving or in air
		camera.transform.origin = camera_start_pos

# Calculate head bob offset based on time
func _calculate_head_bob(time: float) -> Vector3:
	var pos: Vector3 = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos

# Update camera FOV based on movement speed
func _update_fov(delta: float) -> void:
	var velocity_clamped: float = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
	var target_fov: float = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
