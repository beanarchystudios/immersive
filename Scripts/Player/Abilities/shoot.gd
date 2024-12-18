extends RayCast3D

const CLIP_SCALE = 0.05

@onready var fire_rate_timer: Timer = $FireRateTimer
@onready var blaster_preloader: ResourcePreloader = $BlasterPreloader
@onready var handle: Marker3D = $Handle

@export var blaster_offset := Vector3(0.2, -0.2, -0.4)

var current_blaster := 0:
	set(value):
		current_blaster = value
		change_blaster(current_blaster)

var blaster_node: Node3D = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	current_blaster = 0

func _physics_process(delta: float) -> void:
	if Input.is_action_pressed("shoot") and fire_rate_timer.is_stopped() and blaster_node:
		print(shoot())

func change_blaster(new_blaster: int) -> void:
	var blaster: Node3D = blaster_preloader.load_blaster(new_blaster).instantiate() as Node3D
	var blaster_mesh_instance: MeshInstance3D = blaster.get_child(0) as MeshInstance3D
	
	# Scale down blaster to stop clipping.
	handle.position = blaster_offset * CLIP_SCALE
	blaster.scale = Vector3.ONE * CLIP_SCALE
	
	# Flip blaster.
	blaster.rotation_degrees.y = 180
	
	# Stop blaster from casting shadows.
	blaster_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	handle.add_child(blaster)
	
	blaster_node = blaster

func shoot() -> Node3D:
	fire_rate_timer.start()
	
	owner.rotation.y += randf_range(-0.015, 0.015)
	owner.pivot.rotation.x += 0.015
	
	var rot_tween := get_tree().create_tween()
	blaster_node.rotation.x = -0.1
	rot_tween.tween_property(blaster_node, "rotation:x", 0.0, fire_rate_timer.wait_time)
	
	var collider: Node3D = null
	if is_colliding():
		collider = get_collider()
	return collider
