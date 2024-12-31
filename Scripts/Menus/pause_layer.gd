extends CanvasLayer

var game_paused := false:
	set(value):
		game_paused = value
		if not game_paused:
			resume()
		else:
			pause()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		game_paused = not game_paused

func _ready() -> void:
	resume(false)

func pause() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	show()

func resume(capture_mouse := true) -> void:
	if capture_mouse: Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	hide()
	if game_paused:
		game_paused = false

func show_options() -> void:
	pass

func hide_options() -> void:
	pass

func quit() -> void:
	get_tree().quit()
