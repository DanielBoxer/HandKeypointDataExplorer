extends Control

var vr_mode = false

func _ready():
	# start paused
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_node("MenuOverlay").show()
	get_node("InstructionsOverlay").hide()
	get_node("SettingsOverlay").hide()
	
	# add items to settings
	var screen = get_node("SettingsOverlay/HBoxContainer/Column1/ScreenOptions")
	screen.add_item("Windowed")
	screen.add_item("Fullscreen")
	var input = get_node("SettingsOverlay/HBoxContainer/Column1/InputOptions")
	input.add_item("Keyboard")
	input.add_item("VR")
	var kp = get_node("SettingsOverlay/HBoxContainer/Column1/KPOptions")
	kp.add_item("Visible")
	kp.add_item("Invisible")

	
func _input(event):
	if event.is_action_pressed("menu") and not vr_mode:
		# open menu
		get_node("MenuOverlay").show()
		get_node("InstructionsOverlay").hide()
		get_node("SettingsOverlay").hide()
		var new_pause_state = not get_tree().paused
		get_tree().paused = new_pause_state
		visible = new_pause_state
		get_node("/root/Main/LeftHand_11_26/DisplayText").visible = not new_pause_state
		if new_pause_state:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _on_Instructions_pressed():
	get_node("MenuOverlay").hide()
	get_node("InstructionsOverlay").show()

func _on_Back_pressed():
	get_node("MenuOverlay").show()
	get_node("InstructionsOverlay").hide()
	get_node("SettingsOverlay").hide()

func _on_Settings_pressed():
	get_node("MenuOverlay").hide()
	get_node("SettingsOverlay").show()

func _on_Quit_pressed():
	get_tree().quit()

func _on_FPS_value_changed(value):
	var fps_text = get_node("SettingsOverlay/HBoxContainer/Column2/FPSValue")
	Engine.iterations_per_second = value
	fps_text.set_text("FPS: " + str(value))
	
func _on_ScreenOptions_item_selected(_index):
	# toggle fullscreen
	OS.window_fullscreen = !OS.window_fullscreen

func _on_InputOptions_item_selected(_index):
	var camera = get_node("/root/Main/Controller/Head/Camera")
	var vr_camera = get_node("/root/Main/ARVROrigin/ARVRCamera")
	var input_text = get_node("SettingsOverlay/HBoxContainer/Column1/InputLabel")
	if camera.current:
		# start VR
		var VR = ARVRServer.find_interface("OpenVR")
		if VR and VR.initialize():
			vr_camera.current = true
			get_viewport().arvr = true
			get_viewport().hdr = false
			OS.vsync_enabled = false
			Engine.target_fps = 90
			vr_mode = true
			get_tree().paused = false
			visible = false
		else:
			# if VR doesn't initialize, switch back to keyboard mode
			input_text.text = "Input - ERROR: Unable to initialize VR"
			get_node("SettingsOverlay/HBoxContainer/Column1/InputOptions").select(0)
			var t = Timer.new()
			t.set_wait_time(5)
			t.set_one_shot(true)
			self.add_child(t)
			t.start()
			yield(t, "timeout")
			t.queue_free()
			input_text.text = "Input"
	else:
		camera.current = true

func _on_KPOptions_item_selected(_index):
	var keypoints = get_node("/root/Main/Objects/Keypoint_View")
	if keypoints.visible:
		keypoints.visible = false
	else:
		keypoints.visible = true

func _on_ModeOptions_item_selected(_index):
	var mode = get_node("/root/Main/LeftHand_11_26").mode
	if mode == "frame":
		get_node("/root/Main/LeftHand_11_26").mode = "bone"
	else:
		get_node("/root/Main/LeftHand_11_26").mode = "frame"
