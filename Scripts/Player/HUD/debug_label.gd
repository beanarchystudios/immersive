extends Label

var player: CharacterBody3D
var panel: PanelContainer

func _ready() -> void:
	player = get_parent().get_parent().get_parent()
	panel = get_parent()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	panel.visible = player.noclip
	if player.noclip:
		set_text("")
		text += "FPS: " + str(Engine.get_frames_per_second()) + "\n"
		text += "Position: " + str(owner.owner.position) + "\n"
		text += "Velocity: " + str(owner.owner.velocity) + "\n"
