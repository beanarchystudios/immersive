extends RayCast3D

@onready var grab_marker := $GrabMarker

var grabbed_object: Node3D = null

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("grab"):
		if grabbed_object:
			release_grabbed_object()
		elif get_collider() is RigidBody3D:
			attempt_object_grab()

func _physics_process(delta: float) -> void:
	if grabbed_object:
		var vector = grab_marker.global_transform.origin - grabbed_object.global_transform.origin
		grabbed_object.linear_velocity = vector * 20

func attempt_object_grab() -> void:
	grabbed_object = get_collider()
	grabbed_object.lock_rotation = true

func release_grabbed_object() -> void:
	grabbed_object.lock_rotation = false
	grabbed_object = null
