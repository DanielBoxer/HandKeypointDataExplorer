extends Control

var instructions = false
var new_pause_state
onready var display_screen = get_node("/root/Main/LeftHand_11_26/Display_Screen")

func _ready():
	# start in pause menu
	get_tree().paused = true
	visible = true
	display_screen.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _input(event):
	if event.is_action_pressed("menu"):
		# toggle fullscreen when pausing
		OS.window_fullscreen = !OS.window_fullscreen
		new_pause_state = not get_tree().paused
		get_tree().paused = new_pause_state
		visible = new_pause_state
		display_screen.visible = not new_pause_state
		
		# close instructions menu if open
		if instructions:
			get_node("MenuOverlay").show()
			get_node("InstructionsOverlay").hide()
			instructions = false
		if new_pause_state:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if event.is_action_pressed("instructions"):
		if instructions:
			get_node("MenuOverlay").show()
			get_node("InstructionsOverlay").hide()
			instructions = false
		else:
			get_node("MenuOverlay").hide()
			get_node("InstructionsOverlay").show()
			instructions = true
