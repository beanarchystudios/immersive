## A source-like FPS character controller.
class_name Player extends CharacterBody3D

## Possible movement states of the character.
enum MovementState {
	## Not moving.
	IDLE,
	## Walking forward.
	WALKING_FORWARD,
	## Walking backward.
	WALKING_BACKWARD,
	## Strafing left.
	STRAFING_LEFT,
	## Strafing right.
	STRAFING_RIGHT,
	## Running forward.
	RUNNING_FORWARD,
	## Running backward.
	RUNNING_BACKWARD,
	## Running while strafing left.
	STRAFE_RUNNING_LEFT,
	## Running while strafing right.
	STRAFE_RUNNING_RIGHT,
	## Crouching while idle.
	CROUCHING_IDLE,
	## Crouching while moving forward.
	CROUCHING_FORWARD,
	## Crouching while moving backward.
	CROUCHING_BACKWARD,
	## Crouching while strafing left.
	STRAFE_CROUCHING_LEFT,
	## Crouching while strafing right.
	STRAFE_CROUCHING_RIGHT,
	## Jumping.
	JUMPING,
	## Falling.
	FALLING
}

## The FOV of the character when walking. 
const WALK_FOV = 75.0
## The FOV of the character when running. 
const RUN_FOV = 85.0

## The y position of the camera pivot when walking.
const WALK_PIVOT_Y = 0.6
## The y position of the camera pivot when crouching.
const CROUCH_PIVOT_Y = 0.0

@onready var _pivot: Node3D = $Pivot
@onready var _camera: Camera3D = $Pivot/Camera
@onready var _base_collider: CollisionShape3D = $BaseCollider
@onready var _crouch_collider: CollisionShape3D = $CrouchCollider
@onready var _minimap_node: Control = $HUD/Minimap

## The sensitivity of the mouse for turning the camera.
@export var mouse_sensitivity := 0.002

## Enable the minimap.
@export var minimap := false

@export_group("Movement")
## The max speed of the character when walking.
@export var walk_speed := 6.0
## The max speed of the character when running.
@export var run_speed := 8.0
## The max speed of the character when crouching.
@export var crouch_speed := 3.0
## The speed to move at in the air. [br][br]
## [b]Note: This only decreases velocity, it cannot increase velocity past the character's speed.[/b]
@export var air_speed := 2.0
## The speed at which the character accelerates.
@export var acceleration_speed := 0.5
## The speed at which the character decelerates.
@export var deceleration_speed := 0.5

@export_group("Jumping")
## The y velocity when the jump button is pressed.
@export var jump_velocity = 4.5

@export_group("Noclip")
## The speed of the character when in noclip.
@export var noclip_base_speed := 8.0
## The multiplier that is applied when running in noclip.
@export var noclip_run_multiplier := 3.0

## Shows if noclip is enabled or disabled.
var noclip := false
## Shows if the character is running or not.
var running := false
## Shows if the character is crouching or not.
var crouching := false

## The current speed of the character during noclip.
var noclip_speed := 0.0
## The current speed of the character.
var speed := 0.0

## The input direction that is pressed.
var input_dir := Vector2.ZERO
## The direction the character is moved in.
var direction := Vector3.ZERO

## The velocity of the character when they last touched the ground.
var last_ground_velocity := Vector3.ZERO

## The current movement state of the character.
var movement_state: MovementState = MovementState.IDLE

func _ready() -> void:
	noclip_speed = noclip_base_speed
	speed = walk_speed
	
	_crouch_collider.disabled = true
	_minimap_node.visible = minimap
	if not OS.has_feature("web"):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		_pivot.rotate_x(-event.relative.y * mouse_sensitivity)
		_pivot.rotation.x = clampf(_pivot.rotation.x, deg_to_rad(-90), deg_to_rad(90))

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("noclip") and OS.has_feature("debug"):
		noclip = not noclip
		_base_collider.disabled = noclip
		_crouch_collider.disabled = noclip
		last_ground_velocity = velocity
	elif event.is_action("run"):
		running = event.is_pressed()
	elif event.is_action("crouch"):
		crouching = event.is_pressed()
	elif event is InputEventMouseButton:
		if PauseLayer.game_paused: return
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

## Handles the movement of the character while on the ground.
func handle_ground_movement(_delta: float) -> void:
	if direction:
		velocity.x = move_toward(velocity.x, direction.x * speed, acceleration_speed)
		velocity.z = move_toward(velocity.z, direction.z * speed, acceleration_speed)
	else:
		velocity.x = move_toward(velocity.x, 0, deceleration_speed)
		velocity.z = move_toward(velocity.z, 0, deceleration_speed)
	last_ground_velocity = velocity

## Handles the movement of the character while in the air.
func handle_air_movement(delta: float) -> void:
	velocity += get_gravity() * delta

	if direction:
		velocity.x = (direction.x * air_speed) + last_ground_velocity.x
		velocity.z = (direction.z * air_speed) + last_ground_velocity.z
	
	var limited_velocity = Vector2(velocity.x, velocity.z).limit_length(speed)
	velocity.x = limited_velocity.x
	velocity.z = limited_velocity.y

## Handles the movement of the character while in noclip.
func handle_noclip(_delta: float) -> void:
	direction = (_pivot.global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	velocity = direction * noclip_speed

## Handles the state of the character.
func handle_states() -> void:
	var crouch_tween = get_tree().create_tween()
	var fov_tween = get_tree().create_tween()
	crouch_tween.tween_property(_pivot, "position:y", CROUCH_PIVOT_Y if crouching else WALK_PIVOT_Y, 0.15)
	fov_tween.tween_property(_camera, "fov", RUN_FOV if running else WALK_FOV, 0.15)
	
	speed = crouch_speed if crouching else walk_speed
	if not crouching:
		speed = run_speed if running else walk_speed
		noclip_speed = noclip_base_speed * noclip_run_multiplier if running else noclip_base_speed
	
	if is_on_floor():
		if not input_dir.is_zero_approx():
			if not is_zero_approx(input_dir.y):
				if input_dir.y < 0.0:
					if not crouching:
						movement_state = MovementState.RUNNING_FORWARD if running else MovementState.WALKING_FORWARD
					else:
						movement_state = MovementState.CROUCHING_FORWARD
				elif input_dir.y > 0.0:
					if not crouching:
						movement_state = MovementState.RUNNING_BACKWARD if running else MovementState.WALKING_BACKWARD
					else:
						movement_state = MovementState.CROUCHING_BACKWARD
			if not is_zero_approx(input_dir.x):
				if input_dir.x > 0.0:
					if not crouching:
						movement_state = MovementState.STRAFE_RUNNING_RIGHT if running else MovementState.STRAFING_RIGHT
					else:
						movement_state = MovementState.STRAFE_CROUCHING_RIGHT
				elif input_dir.x < 0.0:
					if not crouching:
						movement_state = MovementState.STRAFE_RUNNING_LEFT if running else MovementState.STRAFING_LEFT
					else:
						movement_state = MovementState.STRAFE_CROUCHING_LEFT
		else:
			movement_state = MovementState.CROUCHING_IDLE if crouching else MovementState.IDLE
	else:
		if velocity.y > 0.0:
			movement_state = MovementState.JUMPING
		elif velocity.y < 0.0:
			movement_state = MovementState.FALLING

func _physics_process(delta: float) -> void:
	if PauseLayer.game_paused: return
	
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
	
	move_and_slide()
