extends CharacterBody3D

const WALK_FOV = 75.0
const RUN_FOV = 85.0

const WALK_PIVOT_Y = 0.6
const CROUCH_PIVOT_Y = 0.0

@onready var debug_label: Label = %DebugLabel

@onready var pivot: Node3D = $Pivot
@onready var camera: Camera3D = $Pivot/Camera
@onready var base_collider: CollisionShape3D = $BaseCollider
@onready var crouch_collider: CollisionShape3D = $CrouchCollider

## The sensitivity of the mouse for turning the camera.
@export var mouse_sensitivity := 0.002

@export_group("Movement")
## The max speed of the player when walking.
@export var walk_speed := 6.0
## The max speed of the player when running.
@export var run_speed := 8.0
## The max speed of the player when crouching.
@export var crouch_speed := 3.0

@export var air_speed := 2.0
@export var acceleration_speed := 0.5
@export var deceleration_speed := 0.5

@export_group("Jumping")
@export var jump_velocity = 4.5

@export_group("Noclip")
@export var noclip_base_speed := 8.0
@export var noclip_run_multiplier := 3.0

var noclip := false
var running := false
var crouching := false

var noclip_speed := 0.0
var speed := 0.0

var input_dir := Vector2.ZERO
var direction := Vector3.ZERO

var last_ground_velocity := Vector3.ZERO

func _ready() -> void:
	noclip_speed = noclip_base_speed
	speed = walk_speed
	if not OS.has_feature("web"):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		pivot.rotate_x(-event.relative.y * mouse_sensitivity)
		pivot.rotation.x = clampf(pivot.rotation.x, deg_to_rad(-90), deg_to_rad(90))
	elif event is InputEventMouseButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("noclip") and OS.has_feature("debug"):
		noclip = not noclip
		base_collider.disabled = noclip
		crouch_collider.disabled = noclip
		last_ground_velocity = velocity
	elif event.is_action("run"):
		running = event.is_pressed()
	elif event.is_action("crouch"):
		crouching = event.is_pressed()

func handle_ground_movement(delta: float) -> void:
	if direction:
		velocity.x = move_toward(velocity.x, direction.x * speed, acceleration_speed)
		velocity.z = move_toward(velocity.z, direction.z * speed, acceleration_speed)
	else:
		velocity.x = move_toward(velocity.x, 0, deceleration_speed)
		velocity.z = move_toward(velocity.z, 0, deceleration_speed)
	last_ground_velocity = velocity

func handle_air_movement(delta: float) -> void:
	velocity += get_gravity() * delta

	if direction:
		velocity.x = (direction.x * air_speed) + last_ground_velocity.x
		velocity.z = (direction.z * air_speed) + last_ground_velocity.z
	
	var limited_velocity = Vector2(velocity.x, velocity.z).limit_length(speed)
	velocity.x = limited_velocity.x
	velocity.z = limited_velocity.y

func handle_noclip(delta: float) -> void:
	direction = (pivot.global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	velocity = direction * noclip_speed
	
	debug_label.set_text("")
	debug_label.text += "FPS: " + str(Engine.get_frames_per_second()) + "\n"
	debug_label.text += "Position: " + str(position) + "\n"
	debug_label.text += "Velocity: " + str(velocity) + "\n"

func handle_states() -> void:
	var crouch_tween = get_tree().create_tween()
	var fov_tween = get_tree().create_tween()
	crouch_tween.tween_property(pivot, "position:y", CROUCH_PIVOT_Y if crouching else WALK_PIVOT_Y, 0.15)
	fov_tween.tween_property(camera, "fov", RUN_FOV if running else WALK_FOV, 0.15)
	
	speed = crouch_speed if crouching else walk_speed
	if not crouching:
		speed = run_speed if running else walk_speed
		noclip_speed = noclip_base_speed * noclip_run_multiplier if running else noclip_base_speed

func _physics_process(delta: float) -> void:
	input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	handle_states()
	if not noclip:
		if is_on_floor():
			# Handle jump.
			if Input.is_action_just_pressed("jump"):
				velocity.y = jump_velocity
			handle_ground_movement(delta)
		else:
			handle_air_movement(delta)
	else:
		handle_noclip(delta)
	
	debug_label.get_parent().visible = noclip
	
	move_and_slide()
