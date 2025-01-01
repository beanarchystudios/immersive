extends Node2D
var Playroom = JavaScriptBridge.get_interface("Playroom")
# Keep a reference to the callback so it doesn't get garbage collected
var jsBridgeReferences = []
func bridgeToJS(cb):
	var jsCallback = JavaScriptBridge.create_callback(cb)
	jsBridgeReferences.push_back(jsCallback)
	return jsCallback
 
@export var player_scene: PackedScene = preload("res://Scenes/Player/player.tscn")

@onready var console = JavaScriptBridge.get_interface("console")

var player_states = []
var player_scenes = []
var player_joysticks = []
# Called when the node enters the scene tree for the first time.
func _ready():
	if OS.has_feature("web"):
		# Make Joystick available in browser context so we can create it
		JavaScriptBridge.eval("Joystick = Playroom.Joystick")
		var initOptions = JavaScriptBridge.create_object("Object")
		
		initOptions.gameId = "OndY7lTfNIxfOD9M3q2j"
		initOptions.maxPlayersPerRoom = 32
		console.log(initOptions)
		
		Playroom.insertCoin(initOptions, bridgeToJS(onInsertCoin))
	else:
		var player = player_scene.instantiate()
		get_tree().current_scene.add_child(player)
		player.owner = get_tree().current_scene

# Called when the host has started the game
func onInsertCoin(args):
	print("Coin Inserted")
	Playroom.onPlayerJoin(bridgeToJS(onPlayerJoin))
 
# Called when a new player joins the game
func onPlayerJoin(args):
	var state = args[0]
	print("new player: ", state.id)
	var joystick = addJoystickToPlayer(state)
	var player = player_scene.instantiate()
	var color = Color(state.getProfile().color.hexString)
	
	get_tree().current_scene.add_child(player, true)
	
	player.find_child("BaseMesh").mesh = player.find_child("BaseMesh").mesh.duplicate()
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	player.find_child("BaseMesh").mesh.material = mat
	
	player.name = state.id
	
	player_states.push_back(state)
	player_joysticks.push_back(joystick)
	player_scenes.push_back(player)
	
	# Listen to onQuit event
	var onQuitCb = func onPlayerQuit(args):
		print("player quit: ", state.id)
		player_states.erase(state)
		player_joysticks.erase(joystick)
		player_scenes.erase(player)
		remove_child(player)
	state.onQuit(bridgeToJS(onQuitCb))

# https://docs.joinplayroom.com/components/joystick
func addJoystickToPlayer(state):
	# A dpad + jump button joystick
	var joystickOptions = JavaScriptBridge.create_object("Object")
	joystickOptions.type = "dpad"
	joystickOptions.keyboard = true
	var jumpButton = JavaScriptBridge.create_object("Object")
	jumpButton.id = "jump"
	jumpButton.label = "Jump"
	var buttons = JavaScriptBridge.create_object("Array")
	buttons.push(jumpButton)
	joystickOptions.buttons = buttons
	
	console.log(joystickOptions)
	var joystick = JavaScriptBridge.create_object("Joystick", state, joystickOptions)
	return joystick
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	for i in player_joysticks.size():
		var joystick = player_joysticks[i]
		var state = player_states[i]
		var scene = player_scenes[i]
		if (Playroom.isHost()):
			var dpad = joystick.dpad()
			
			if dpad.x == "left":
				scene.input_dir.x = -1
			elif dpad.x == "right":
				scene.input_dir.x = 1
			else:
				scene.input_dir.x = 0
			
			if dpad.y == "up":
				scene.input_dir.y = -1
			elif dpad.y == "down":
				scene.input_dir.y = 1
			else:
				scene.input_dir.y = 0
			scene.input_dir = scene.input_dir.normalized()
			
			#if joystick.isPressed("jump"):
			if Input.is_action_just_pressed("jump"):
				if scene.name == Playroom.me().id:
					scene.jump()
			state.setState("px", scene.get_position().x)
			state.setState("py", scene.get_position().y)
			state.setState("pz", scene.get_position().z)
			scene._camera.make_current()
		else:
			if (!state.getState("px")): pass
			scene.position = Vector3(state.getState("px"), state.getState("py"), state.getState("pz"))
