class_name Shoot extends RayCast3D

const CLIP_SCALE = 0.05
const ADS_TRANSITION_TIME = 0.15
const BULLET_HOLE = preload("res://Scenes/Effects/bullet_hole.tscn")

@onready var fire_rate_timer: Timer = $FireRateTimer
@onready var handle: Marker3D = $Handle

@export var blaster_resources: Array[Blaster] = [
	preload("res://Assets/Resources/Blasters/Kenney/blasterA.tres"),
	preload("res://Assets/Resources/Blasters/Kenney/blasterB.tres")
]

@export_group("Sway")
@export_range(0.5, 10.0, 0.1) var sway_lerp := 5.0
@export_range(0.5, 10.0, 0.1) var sway_threshold := 5.0
@export_range(0.01, 1.0, 0.01) var sway_amount := 0.1


var current_blaster := 0:
	set(value):
		current_blaster = value
		current_blaster %= blaster_resources.size()
		change_blaster(current_blaster)

var blaster_node: Node3D = null
var blaster_resource: Blaster = null

var ads := false
var mouse_mov := Vector2.ZERO

func _input(event: InputEvent) -> void:
	if event.is_action("ads"):
		ads = event.is_pressed()
		if ads:
			enter_ads()
		else:
			leave_ads()
	elif event.is_action_pressed("next_blaster"):
		current_blaster += 1
	elif event.is_action_pressed("prev_blaster"):
		current_blaster -= 1
	elif event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		mouse_mov = -event.relative

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	current_blaster = 0

func _physics_process(delta: float) -> void:
	sway_blaster(delta)
	
	if Input.is_action_pressed("shoot") and fire_rate_timer.is_stopped() and blaster_node and blaster_resource and blaster_resource.can_shoot:
		print(shoot())

# Sway the blaster based on mouse movement.
func sway_blaster(delta: float) -> void:
	if not mouse_mov.is_zero_approx() and blaster_node:
		if not is_zero_approx(mouse_mov.x):
			if mouse_mov.x < -sway_threshold: # Sway left.
				blaster_node.rotation = blaster_node.rotation.lerp(Vector3.DOWN * sway_amount, delta * sway_lerp)
			elif mouse_mov.x > sway_threshold: # Sway right.
				blaster_node.rotation = blaster_node.rotation.lerp(Vector3.UP * sway_amount, delta * sway_lerp)
			else: # Return to normal.
				blaster_node.rotation = blaster_node.rotation.lerp(Vector3.ZERO, delta * sway_lerp)
		if not is_zero_approx(mouse_mov.y):
			if mouse_mov.y < -sway_threshold: # Sway down.
				blaster_node.rotation = blaster_node.rotation.lerp(Vector3.LEFT * sway_amount, delta * sway_lerp)
			elif mouse_mov.y > sway_threshold: # Sway up.
				blaster_node.rotation = blaster_node.rotation.lerp(Vector3.RIGHT * sway_amount, delta * sway_lerp)
			else: # Return to normal.
				blaster_node.rotation = blaster_node.rotation.lerp(Vector3.ZERO, delta * sway_lerp)

func change_blaster(new_blaster: int) -> void:
	if blaster_resources.size() < new_blaster: return
	
	if blaster_node:
		blaster_node.queue_free()
		blaster_node = null
	
	blaster_resource = blaster_resources[new_blaster]
	
	var blaster: Node3D = blaster_resource.model.instantiate() as Node3D
	var blaster_mesh_instance: MeshInstance3D = blaster.get_child(0) as MeshInstance3D
	
	# Scale down blaster to stop clipping.
	handle.position = blaster_resource.base_offset * CLIP_SCALE
	blaster.scale = Vector3.ONE * CLIP_SCALE
	
	# Flip blaster.
	handle.rotation_degrees.y = 180
	
	# Stop blaster from casting shadows.
	blaster_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	handle.add_child(blaster)
	blaster_node = blaster
	
	fire_rate_timer.wait_time = blaster_resource.fire_rate

func shoot() -> Node3D:
	fire_rate_timer.start()
	
	var recoil := blaster_resource.ads_recoil if ads else blaster_resource.base_recoil
	print(recoil)
	
	owner.rotation.y += randf_range(-recoil / 2, recoil / 2)
	owner._pivot.rotation.x += recoil
	
	var rot_tween := get_tree().create_tween()
	blaster_node.rotation.x = -recoil * 5
	rot_tween.tween_property(blaster_node, "rotation:x", 0.0, fire_rate_timer.wait_time)
	
	var collider: Node3D = null
	if is_colliding():
		spawn_bullet_hole()
		collider = get_collider()
	return collider

func align_with_y(body, new_y):
	var xform = body.global_transform
	xform.basis.y = new_y
	xform.basis.x = -xform.basis.z.cross(new_y)
	xform.basis = xform.basis.orthonormalized()
	return xform

func spawn_bullet_hole() -> void:
	var bullet_hole := BULLET_HOLE.instantiate() as Sprite3D
	owner.owner.add_child(bullet_hole)
	
	var bh_normal := get_collision_normal()
	bullet_hole.position = get_collision_point() + (bh_normal / 50)
	if bh_normal != Vector3.FORWARD and bh_normal != Vector3.BACK:
		bullet_hole.global_transform = align_with_y(bullet_hole, bh_normal)
	else:
		bullet_hole.rotation_degrees.x = 90
	print(bullet_hole.global_position)

func enter_ads() -> void:
	var ads_tween := get_tree().create_tween()
	ads_tween.set_ease(Tween.EASE_IN_OUT)
	ads_tween.set_trans(Tween.TRANS_QUAD)
	ads_tween.tween_property(handle, "position", blaster_resource.ads_offset * CLIP_SCALE, ADS_TRANSITION_TIME)

func leave_ads() -> void:
	var ads_tween := get_tree().create_tween()
	ads_tween.set_ease(Tween.EASE_IN_OUT)
	ads_tween.set_trans(Tween.TRANS_QUAD)
	ads_tween.tween_property(handle, "position", blaster_resource.base_offset * CLIP_SCALE, ADS_TRANSITION_TIME)
