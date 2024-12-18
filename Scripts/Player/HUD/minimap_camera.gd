extends Camera3D


func _physics_process(delta: float) -> void:
	position = owner.owner.player.position
	position.y = 20.0
