extends Control

var _is_vr_mode_activated := false
var _is_dataset_text_visible := true
var _is_debug_angle_text_visible := false

var location = "SettingsOverlay/Settings/"
onready var menu_overlay := get_node("MenuOverlay")
onready var instructions_overlay := get_node("InstructionsOverlay")
onready var settings_overlay := get_node("SettingsOverlay")
onready var input_frame_label := get_node(
	location + "FrameSettings/Column/NextFrameContainer/InputFrameLabel"
)
onready var input_options: OptionButton = get_node(
	location + "InputSettings/Column/InputContainer/InputOptions"
)
onready var input_frame: SpinBox = get_node(
	location + "FrameSettings/Column/NextFrameContainer/InputFrame"
)
onready var controller := get_node("/root/Main/Controller")
onready var plugin_checkbox: CheckBox = get_node(
	location + "FrameSettings/Column/PluginContainer/PluginOptions"
)
onready var hands := get_node("/root/Main/Hands")
onready var keypoint_view := get_node("/root/Main/KeypointView")
onready var side_keypoints_checkbox: CheckBox = get_node(
	location + "ViewSettings/Column/SideKPContainer/SideKPOptions"
)
onready var debug_options_checkbox = get_node(
	location + "DebugSettings/Column/DebugContainer/DebugOptions"
)
onready var popup := get_node("SettingsOverlay/Popup")
onready var current_frame_options_checkbox = get_node(
	location + "FrameSettings/Column/CurrentFrameContainer/CurrentFrameOptions"
)
onready var keypoint_view_checkbox = get_node(
	location + "ViewSettings/Column/KPContainer/KPOptions"
)
onready var left_hand_view_checkbox = get_node(
	location + "ViewSettings/Column/LeftHandViewContainer/LeftHandView"
)
onready var right_hand_view_checkbox = get_node(
	location + "ViewSettings/Column/RightHandViewContainer/RightHandView"
)
onready var current_frame_checkbox: CheckBox = get_node(
	location + "FrameSettings/Column/CurrentFrameContainer/CurrentFrameOptions"
)
onready var hand_debug_options: OptionButton = get_node(
	location + "DebugSettings/Column/HandDebugContainer/HandDebugOptions"
)
onready var hand_debug_options_text = get_node(
	location + "DebugSettings/Column/HandDebugContainer/HandDebugLabel"
)
onready var dataset_text = get_node("/root/Main/Hands/DisplayContainer/DatasetText")
onready var debug_angle_text = get_node(
	"/root/Main/Hands/DisplayContainer/DebugAngleText"
)
onready var debug_frame_text = get_node(
	location + "DebugSettings/Column/DebugFrameContainer/DebugFrameLabel"
)
onready var debug_frame = get_node(
	location + "DebugSettings/Column/DebugFrameContainer/DebugFrame"
)
onready var marker := get_node("/root/Main/Debugger/Tools/Marker")
onready var global_axis := get_node("/root/Main/Debugger/Tools/GlobalAxis")
onready var bone_axis := get_node("/root/Main/Debugger/Tools/BoneAxis")
onready var marker_checkbox := get_node(
	location + "DebugSettings/Column/ShowMarkerContainer/ShowMarkerCheckbox"
)
onready var global_axis_checkbox := get_node(
	location + "DebugSettings/Column/ShowGlobalAxisContainer/ShowGlobalAxisCheckbox"
)
onready var bone_axis_checkbox := get_node(
	location + "DebugSettings/Column/ShowBoneAxisContainer/ShowBoneAxisCheckbox"
)
onready var debugger = get_node("/root/Main/Debugger")


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
	var screen_options: OptionButton = get_node(
		location + "DisplaySettings/Column/ScreenContainer/ScreenOptions"
	)
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
	get_node("SettingsOverlay/Popup/PopupText").set_text(text)
	var timer := Timer.new()
	timer.set_wait_time(5)
	timer.set_one_shot(true)
	self.add_child(timer)
	timer.start()
	yield(timer, "timeout")
	timer.queue_free()
	popup.visible = false


func _on_Instructions_pressed() -> void:
	menu_overlay.hide()
	instructions_overlay.show()


func _on_Back_pressed() -> void:
	menu_overlay.show()
	instructions_overlay.hide()
	settings_overlay.hide()


func _on_Settings_pressed() -> void:
	menu_overlay.hide()
	settings_overlay.show()


func _on_Quit_pressed() -> void:
	get_tree().quit()


func _on_FPS_value_changed(value: int) -> void:
	if debug_options_checkbox.pressed == false:
		var fps_text: Label = get_node(
			location + "FrameSettings/Column/FPSContainer/FPSValue"
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
		location + "InputSettings/Column/MouseSensitivityContainer/MouseSensitivityValue"
	)
	mouse_sensitivity_text.set_text("Mouse Sensitivity: " + str(value))
	controller.mouse_sensitivity = value


func _on_MovementSpeed_value_changed(value: int) -> void:
	var movement_speed_text := get_node(
		location + "InputSettings/Column/MovementSpeedContainer/MovementSpeedValue"
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
		current_frame_options_checkbox.pressed = true


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
