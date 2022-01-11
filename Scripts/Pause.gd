extends Control

var _is_vr_mode_activated := false


func _ready() -> void:
	# start paused
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_node("MenuOverlay").show()
	get_node("InstructionsOverlay").hide()
	get_node("SettingsOverlay").hide()

	# add items to sliders
	var screen_options: OptionButton = get_node(
		"SettingsOverlay/SettingsContainer/Column3/ScreenOptions"
	)
	screen_options.add_item("Windowed")
	screen_options.add_item("Fullscreen")
	var input_options: OptionButton = get_node(
		"SettingsOverlay/SettingsContainer/Column3/InputOptions"
	)
	input_options.add_item("Keyboard")
	input_options.add_item("VR")
	var input_frame: SpinBox = get_node(
		"SettingsOverlay/SettingsContainer/Column4/InputFrame"
	)
	input_frame.max_value = get_node("/root/ImportData").keypoint_data.size() - 1


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("menu") and not _is_vr_mode_activated:
		# open menu
		get_node("MenuOverlay").show()
		get_node("InstructionsOverlay").hide()
		get_node("SettingsOverlay").hide()
		var new_pause_state: bool = not get_tree().paused
		get_tree().paused = new_pause_state
		visible = new_pause_state
		get_node("/root/Main/LeftHand/DisplayText").visible = not new_pause_state
		if new_pause_state:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			get_node("SettingsOverlay/SettingsContainer/Column4/InputFrameLabel").set_text(
				"Input Next Frame: Not Set"
			)


func _on_Instructions_pressed() -> void:
	get_node("MenuOverlay").hide()
	get_node("InstructionsOverlay").show()


func _on_Back_pressed() -> void:
	get_node("MenuOverlay").show()
	get_node("InstructionsOverlay").hide()
	get_node("SettingsOverlay").hide()


func _on_Settings_pressed() -> void:
	get_node("MenuOverlay").hide()
	get_node("SettingsOverlay").show()


func _on_Quit_pressed() -> void:
	get_tree().quit()


func _on_FPS_value_changed(value: int) -> void:
	var fps_text := get_node("SettingsOverlay/SettingsContainer/Column2/FPSValue")
	Engine.iterations_per_second = value
	fps_text.set_text("FPS: " + str(value))


func _on_ScreenOptions_item_selected(_index: int) -> void:
	# toggle fullscreen
	OS.window_fullscreen = !OS.window_fullscreen


func _on_InputOptions_item_selected(_index: int) -> void:
	var camera := get_node("/root/Main/Controller/Head/Camera")
	var vr_camera := get_node("/root/Main/ARVROrigin/ARVRCamera")
	var input_text := get_node("SettingsOverlay/SettingsContainer/Column3/InputLabel")
	if camera.current:
		# start VR
		var VR: ARVRInterface = ARVRServer.find_interface("OpenVR")
		if VR and VR.initialize():
			vr_camera.current = true
			get_viewport().arvr = true
			get_viewport().hdr = false
			OS.vsync_enabled = false
			Engine.target_fps = 90
			_is_vr_mode_activated = true
			get_tree().paused = false
			visible = false
		else:
			# if VR doesn't initialize, switch back to keyboard mode
			input_text.text = "Input - ERROR: Unable to initialize VR"
			get_node("SettingsOverlay/SettingsContainer/Column3/InputOptions").select(0)
			var timer := Timer.new()
			timer.set_wait_time(5)
			timer.set_one_shot(true)
			self.add_child(timer)
			timer.start()
			yield(timer, "timeout")
			timer.queue_free()
			input_text.text = "Input"
	else:
		camera.current = true


func _on_MouseSensitivity_value_changed(value: int) -> void:
	get_node("SettingsOverlay/SettingsContainer/Column2/MouseSensitivityValue").set_text(
		"Mouse Sensitivity: " + str(value)
	)
	get_node("/root/Main/Controller").mouse_sensitivity = value


func _on_MovementSpeed_value_changed(value: int) -> void:
	get_node("SettingsOverlay/SettingsContainer/Column2/MovementSpeedValue").set_text(
		"Movement Speed: " + str(value)
	)
	get_node("/root/Main/Controller").speed = value


func _on_InputFrame_value_changed(value: int) -> void:
	var input_frame: SpinBox = get_node(
		"SettingsOverlay/SettingsContainer/Column4/InputFrame"
	)
	if value >= 0:
		get_node("/root/Main/LeftHand").frame_number = value
		get_node("SettingsOverlay/SettingsContainer/Column4/InputFrameLabel").set_text(
			"Input Next Frame: Frame " + str(value)
		)
		input_frame.value = -1


func _on_CurrentFrameOptions_toggled(button_pressed: bool) -> void:
	get_node("/root/Main/LeftHand").set_physics_process(not button_pressed)
	get_node("/root/Main/KeypointView").set_physics_process(not button_pressed)


func _on_PluginOptions_toggled(button_pressed: bool) -> void:
	get_node("/root/Main/LeftHand").is_plugin_activated = button_pressed
	var side_keypoint_checkbox := get_node(
		"SettingsOverlay/SettingsContainer/Column1/Row4/SideKPOptions"
	)
	if side_keypoint_checkbox.is_pressed():
		side_keypoint_checkbox.pressed = false


func _on_KPOptions_toggled(button_pressed: bool) -> void:
	get_node("/root/Main/LeftHand/Armature/Skeleton/Hand_L").visible = not button_pressed


func _on_SideKPOptions_toggled(button_pressed: bool) -> void:
	var side_keypoint_text := get_node(
		"SettingsOverlay/SettingsContainer/Column1/Row4/SideKPLabel"
	)
	var side_keypoints := get_node("/root/Main/KeypointView")
	var side_keypoint_checkbox = get_node(
		"SettingsOverlay/SettingsContainer/Column1/Row4/SideKPOptions"
	)
	var plugin_checkbox := get_node(
		"SettingsOverlay/SettingsContainer/Column1/Row2/PluginOptions"
	)
	var is_plugin_checked: bool = plugin_checkbox.is_pressed()
	if is_plugin_checked:
		side_keypoints.visible = false
		side_keypoint_checkbox.pressed = false
		if side_keypoint_text.get_text() == "Side Keypoint View":
			side_keypoint_text.set_text("Unavailable with plugin")
			var timer := Timer.new()
			timer.set_wait_time(5)
			timer.set_one_shot(true)
			self.add_child(timer)
			timer.start()
			yield(timer, "timeout")
			timer.queue_free()
			side_keypoint_text.set_text("Side Keypoint View")

	else:
		side_keypoints.visible = button_pressed
