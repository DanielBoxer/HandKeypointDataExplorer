extends Control

var _is_vr_mode_activated := false
var _is_dataset_text_visible := true
var _is_debug_angle_text_visible := false
var _location = "SettingsOverlay/Settings/"

onready var menu_overlay := get_node("MenuOverlay")
onready var instructions_overlay := get_node("InstructionsOverlay")
onready var settings_overlay := get_node("SettingsOverlay")
onready var controller := get_node("/root/Main/Controller")
onready var hands := get_node("/root/Main/Hands")
onready var keypoint_view := get_node("/root/Main/KeypointView")
onready var popup := get_node("SettingsOverlay/Popup")
onready var dataset_text = get_node("/root/Main/Hands/DisplayContainer/DatasetText")
onready var input_frame_label := get_node(
	_location + "FrameSettings/Column/NextFrameContainer/InputFrameLabel"
)
onready var input_frame: SpinBox = get_node(
	_location + "FrameSettings/Column/NextFrameContainer/InputFrame"
)
onready var fps_slider := get_node(_location + "FrameSettings/Column/FPSContainer/FPS")
onready var current_frame_checkbox: CheckBox = get_node(
	_location + "FrameSettings/Column/CurrentFrameContainer/CurrentFrameOptions"
)
onready var plugin_checkbox: CheckBox = get_node(
	_location + "FrameSettings/Column/PluginContainer/PluginOptions"
)
onready var left_hand_view_checkbox = get_node(
	_location + "ViewSettings/Column/LeftHandViewContainer/LeftHandView"
)
onready var right_hand_view_checkbox = get_node(
	_location + "ViewSettings/Column/RightHandViewContainer/RightHandView"
)
onready var keypoint_view_checkbox = get_node(
	_location + "ViewSettings/Column/KPContainer/KPOptions"
)
onready var side_keypoints_checkbox: CheckBox = get_node(
	_location + "ViewSettings/Column/SideKPContainer/SideKPOptions"
)
onready var display_text_checkbox := get_node(
	_location + "ViewSettings/Column/DisplayTextContainer/DisplayTextOptions"
)
onready var screen_options := get_node(
	_location + "DisplaySettings/Column/ScreenContainer/ScreenOptions"
)
onready var mouse_sensitivity_slider: HSlider = get_node(
	_location + "InputSettings/Column/MouseSensitivityContainer/MouseSensitivity"
)
onready var movement_speed_slider: HSlider = get_node(
	_location + "InputSettings/Column/MovementSpeedContainer/MovementSpeed"
)
onready var input_options: OptionButton = get_node(
	_location + "InputSettings/Column/InputContainer/InputOptions"
)
onready var bvh_frame_start_input: SpinBox = get_node(
	_location + "BVHSettings/Column/FrameStartContainer/FrameStartInput"
)
onready var bvh_frame_end_input: SpinBox = get_node(
	_location + "BVHSettings/Column/FrameEndContainer/FrameEndInput"
)
onready var bvh_left_hand_checkbox: CheckBox = get_node(
	_location + "BVHSettings/Column/LeftHandBVHContainer/LeftHandBVHCheckbox"
)
onready var bvh_right_hand_checkbox: CheckBox = get_node(
	_location + "BVHSettings/Column/RightHandBVHContainer/RightHandBVHCheckbox"
)
onready var debug_options_checkbox = get_node(
	_location + "DebugSettings/Column/DebugContainer/DebugOptions"
)
onready var debug_frame_text = get_node(
	_location + "DebugSettings/Column/DebugFrameContainer/DebugFrameLabel"
)
onready var debug_frame = get_node(
	_location + "DebugSettings/Column/DebugFrameContainer/DebugFrame"
)
onready var hand_debug_options_text = get_node(
	_location + "DebugSettings/Column/HandDebugContainer/HandDebugLabel"
)
onready var hand_debug_options: OptionButton = get_node(
	_location + "DebugSettings/Column/HandDebugContainer/HandDebugOptions"
)
onready var marker_checkbox := get_node(
	_location + "DebugSettings/Column/ShowMarkerContainer/ShowMarkerCheckbox"
)
onready var global_axis_checkbox := get_node(
	_location + "DebugSettings/Column/ShowGlobalAxisContainer/ShowGlobalAxisCheckbox"
)
onready var bone_axis_checkbox := get_node(
	_location + "DebugSettings/Column/ShowBoneAxisContainer/ShowBoneAxisCheckbox"
)
onready var debugger = get_node("/root/Main/Debugger")
onready var debug_angle_text = get_node(
	"/root/Main/Hands/DisplayContainer/DebugAngleText"
)
onready var marker := get_node("/root/Main/Debugger/Tools/Marker")
onready var global_axis := get_node("/root/Main/Debugger/Tools/GlobalAxis")
onready var bone_axis := get_node("/root/Main/Debugger/Tools/BoneAxis")


func _ready() -> void:
	# start paused
	pause()
	add_button_items()
	popup.visible = false


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("menu") and not _is_vr_mode_activated:
		pause()


func pause() -> void:
	# open menu and pause
	var new_pause_state: bool = not get_tree().paused
	get_tree().paused = new_pause_state
	menu_overlay.show()
	instructions_overlay.hide()
	settings_overlay.hide()
	self.visible = new_pause_state
	popup.visible = false
	if _is_dataset_text_visible:
		dataset_text.visible = not new_pause_state
	if _is_debug_angle_text_visible:
		debug_angle_text.visible = not new_pause_state
	if new_pause_state:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		input_frame_label.set_text("Next Frame: Not Set")


func add_button_items() -> void:
	# add items to sliders
	screen_options.add_item("Windowed")
	screen_options.add_item("Fullscreen")

	input_options.add_item("Keyboard")
	input_options.add_item("VR")
	input_frame.max_value = (
		get_node("/root/ImportData").keypoint_data["left_hand_data"].size()
		- 1
	)
	debug_frame.max_value = input_frame.max_value
	hand_debug_options.add_item("Left Hand")
	hand_debug_options.add_item("Right Hand")


func activate_popup(text: String) -> void:
	popup.visible = true
	get_node("SettingsOverlay/Popup/PopupContainer/PopupText").set_text(text)


func _on_Instructions_pressed() -> void:
	menu_overlay.hide()
	instructions_overlay.show()


func _on_Settings_pressed() -> void:
	menu_overlay.hide()
	settings_overlay.show()


func _on_Unpause_pressed():
	pause()


func _on_Restart_pressed():
	var _error_message: int = get_tree().reload_current_scene()
	pause()


func _on_Quit_pressed() -> void:
	get_tree().quit()


func _on_Back_pressed() -> void:
	menu_overlay.show()
	instructions_overlay.hide()
	settings_overlay.hide()
	popup.visible = false


func _on_FPS_value_changed(value: int) -> void:
	if debug_options_checkbox.pressed == false:
		var fps_text: Label = get_node(
			_location + "FrameSettings/Column/FPSContainer/FPSValue"
		)
		Engine.iterations_per_second = value
		fps_text.set_text("FPS: " + str(value))
	else:
		activate_popup("FPS unavailable in debug mode")


func _on_ScreenOptions_item_selected(_index: int) -> void:
	# toggle fullscreen
	OS.window_fullscreen = !OS.window_fullscreen


func _on_InputOptions_item_selected(_index: int) -> void:
	var camera: Camera = get_node("/root/Main/Controller/Head/Camera")
	var vr_camera: ARVRCamera = get_node("/root/Main/Objects/ARVROrigin/ARVRCamera")
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
			activate_popup("ERROR: Unable to initialize VR")
			input_options.select(0)
	else:
		camera.current = true


func _on_MouseSensitivity_value_changed(value: int) -> void:
	var mouse_sensitivity_text := get_node(
		_location + "InputSettings/Column/MouseSensitivityContainer/MouseSensitivityValue"
	)
	mouse_sensitivity_text.set_text("Mouse Sensitivity: " + str(value))
	controller.mouse_sensitivity = value


func _on_MovementSpeed_value_changed(value: int) -> void:
	var movement_speed_text := get_node(
		_location + "InputSettings/Column/MovementSpeedContainer/MovementSpeedValue"
	)
	movement_speed_text.set_text("Movement Speed: " + str(value))
	controller.speed = value


func _on_InputFrame_value_changed(value: int) -> void:
	if plugin_checkbox.pressed == false:
		if value >= 0:
			hands.frame_number = value
			keypoint_view.frame_number = value

			input_frame_label.set_text("Next Frame: " + str(value))
			input_frame.value = -1
	else:
		activate_popup("Next frame input unavailable while plugin is on")
		input_frame.value = -1


func _on_CurrentFrameOptions_toggled(button_pressed: bool) -> void:
	hands.set_physics_process(not button_pressed)
	keypoint_view.set_physics_process(not button_pressed)
	if debug_options_checkbox.pressed == true:
		activate_popup("Can't go to the next frame in debug mode")
		current_frame_checkbox.pressed = true


func _on_PluginOptions_toggled(button_pressed: bool) -> void:
	if debug_options_checkbox.pressed == false:
		hands.is_plugin_activated = button_pressed
		if side_keypoints_checkbox.is_pressed():
			side_keypoints_checkbox.pressed = false
	else:
		activate_popup("Plugin data unavailable in debug mode")
		plugin_checkbox.pressed = false


func _on_KPOptions_toggled(button_pressed: bool) -> void:
	if debug_options_checkbox.pressed == false:
		var hand_mesh_left: MeshInstance = get_node(
			"/root/Main/Hands/LeftHand/Armature/Skeleton/Hand_L"
		)
		var hand_keypoints_left = get_node(
			"/root/Main/Hands/LeftHand/Armature/Skeleton/Keypoints"
		)
		hand_mesh_left.visible = not button_pressed
		hand_keypoints_left.visible = button_pressed
		var hand_mesh_right: MeshInstance = get_node(
			"/root/Main/Hands/RightHand/Armature/Skeleton/Hand_L"
		)
		var hand_keypoints_right = get_node(
			"/root/Main/Hands/RightHand/Armature/Skeleton/Keypoints"
		)
		hand_mesh_right.visible = not button_pressed
		hand_keypoints_right.visible = button_pressed
	else:
		activate_popup("Keypoint view unavailable in debug mode")
		keypoint_view_checkbox.pressed = false


func _on_SideKPOptions_toggled(button_pressed: bool) -> void:
	if debug_options_checkbox.pressed == false:
		var is_plugin_checked: bool = plugin_checkbox.is_pressed()
		if is_plugin_checked:
			keypoint_view.visible = false
			side_keypoints_checkbox.pressed = false
			activate_popup("Side Keypoint View unavailable while plugin is on")
		else:
			keypoint_view.visible = button_pressed
	else:
		get_node("/root/Main/Debugger/KeypointView").visible = button_pressed


func _on_LeftHandView_toggled(button_pressed: bool) -> void:
	get_node("/root/Main/Hands/LeftHand").visible = button_pressed
	get_node("/root/Main/KeypointView/left_hand").visible = button_pressed
	if debug_options_checkbox.pressed == true:
		activate_popup("Show left hand unavailable in debug mode")
		left_hand_view_checkbox.pressed = false


func _on_RightHandView_toggled(button_pressed: bool) -> void:
	get_node("/root/Main/Hands/RightHand").visible = button_pressed
	get_node("/root/Main/KeypointView/right_hand").visible = button_pressed
	if debug_options_checkbox.pressed == true:
		activate_popup("Show right hand unavailable in debug mode")
		right_hand_view_checkbox.pressed = false


func _on_DisplayTextOptions_toggled(button_pressed: bool) -> void:
	_is_dataset_text_visible = button_pressed


func _on_DebugOptions_toggled(button_pressed: bool) -> void:
	debugger.debug_new_frame_update()
	debugger.set_debug_mode(button_pressed)
	_is_debug_angle_text_visible = button_pressed
	current_frame_checkbox.pressed = true
	left_hand_view_checkbox.pressed = false
	right_hand_view_checkbox.pressed = false
	plugin_checkbox.pressed = false
	keypoint_view_checkbox.pressed = false
	side_keypoints_checkbox.pressed = true
	get_node("/root/Main/Debugger/Hands").visible = button_pressed
	get_node("/root/Main/Debugger/KeypointView").visible = button_pressed
	get_node("/root/Main/Debugger/Tools").visible = button_pressed
	marker_checkbox.pressed = false
	global_axis_checkbox.pressed = true
	bone_axis_checkbox.pressed = false


func _on_ShowMarkerCheckbox_toggled(button_pressed: bool) -> void:
	marker.visible = button_pressed


func _on_ShowGlobalAxisCheckbox_toggled(button_pressed: bool) -> void:
	global_axis.visible = button_pressed


func _on_ShowBoneAxisCheckbox_toggled(button_pressed: bool) -> void:
	bone_axis.visible = button_pressed


func _on_DebugFrame_value_changed(value: int) -> void:
	if value >= 0:
		debugger.frame_number = value
		debug_frame_text.set_text("Frame To Debug: " + str(value))
		debugger.debug_new_frame_update()


func _on_HandDebugOptions_item_selected(index: int) -> void:
	if index == 0:
		debugger.set_hand_selection("left")
	else:
		debugger.set_hand_selection("right")


func _on_InputFrameInfo_pressed() -> void:
	activate_popup(
		(
			"Set the next frame of data that will be shown\n"
			+ "The input field will always stay at -1"
		)
	)


func _on_FPSInfo_pressed() -> void:
	activate_popup(
		"Change the frames per second (FPS) of data playback\nFPS can be from 1 to 90"
	)


func _on_CurrentFrameInfo_pressed() -> void:
	activate_popup("Pause data playback and stay on the current frame")


func _on_PluginInfo_pressed() -> void:
	activate_popup(
		(
			"Keypoint data will be taken from the keypoints.c file "
			+ "instead of the JSON input files"
		)
	)


func _on_LeftHandViewInfo_pressed() -> void:
	activate_popup("Show/hide the left hand model")


func _on_RightHandViewInfo_pressed() -> void:
	activate_popup("Show/hide the right hand model")


func _on_KPInfo_pressed() -> void:
	activate_popup(
		(
			"Activate keypoint visualization of the hand models\n"
			+ "Only the keypoints will be visible\n"
			+ "This is based on the hand models, not the data"
		)
	)


func _on_SideKPInfo_pressed() -> void:
	activate_popup(
		(
			"Show a keypoint visualization beside the hand models\n"
			+ "This is based on the data input"
		)
	)


func _on_DisplayTextInfo_pressed() -> void:
	activate_popup("Show/hide the text that displays the current frame")


func _on_ScreenInfo_pressed() -> void:
	activate_popup("Change the application to be fullscreen or windowed")


func _on_MouseSensitivityInfo_pressed() -> void:
	activate_popup(
		"Change the mouse sensitivity\nThis only affects the mouse outside of the menu"
	)


func _on_MovementSpeedInfo_pressed() -> void:
	activate_popup("Change the movement speed of the camera")


func _on_InputInfo_pressed() -> void:
	activate_popup("Turn VR mode on or off\nThe menu is disabled in VR mode")


func _on_FrameStartInfo_pressed() -> void:
	activate_popup(
		(
			"Set the start frame of the .bvh file output\n"
			+ "This must be less than or equal to the end frame"
		)
	)


func _on_FrameEndInfo_pressed() -> void:
	activate_popup(
		(
			"Set the end frame of the .bvh file output\n"
			+ "This must be greater than or equal to the start frame"
		)
	)


func _on_LeftHandBVHInfo_pressed() -> void:
	activate_popup("Generate a .bvh file for the left hand")


func _on_RightHandBVHInfo_pressed() -> void:
	activate_popup("Generate a .bvh file for the right hand")


func _on_BVHInfo_pressed() -> void:
	activate_popup(
		(
			"Generate a .bvh file to the Output folder\n"
			+ "This file will contain armature and animation data\n"
			+ "The .bvh file can be imported to other software"
		)
	)


func _on_Close_pressed():
	popup.visible = false


func _on_ResetFrameSettings_pressed():
	input_frame.value = 0
	fps_slider.value = 1
	current_frame_checkbox.pressed = false
	plugin_checkbox.pressed = false


func _on_ResetViewSettings_pressed():
	left_hand_view_checkbox.pressed = true
	right_hand_view_checkbox.pressed = false
	keypoint_view_checkbox.pressed = false
	side_keypoints_checkbox.pressed = false
	display_text_checkbox.pressed = true


func _on_ResetDisplaySettings_pressed():
	screen_options.select(0)


func _on_ResetInputSettings_pressed():
	mouse_sensitivity_slider.value = 5
	movement_speed_slider.value = 3


func _on_ResetBVHSettings_pressed():
	bvh_frame_start_input.value = 1
	bvh_frame_end_input.value = 1
	bvh_left_hand_checkbox.pressed = true
	bvh_right_hand_checkbox.pressed = false
