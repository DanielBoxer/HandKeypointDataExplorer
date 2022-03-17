extends Control

var _is_vr_mode_activated := false
var _is_dataset_text_visible := true

onready var pause_script := get_node("/root/Main/Pause")
onready var keypoint_view := get_node("/root/Main/KeypointView")
onready var hands := get_node("/root/Main/Hands")
onready var controller := get_node("/root/Main/Controller")

# frame settings
export var input_frame_label_path: NodePath
onready var input_frame_label := get_node(input_frame_label_path)
export var input_frame_path: NodePath
onready var input_frame: SpinBox = get_node(input_frame_path)
export var fps_text_path: NodePath
onready var fps_text: Label = get_node(fps_text_path)
export var fps_slider_path: NodePath
onready var fps_slider := get_node(fps_slider_path)
export var current_frame_checkbox_path: NodePath
onready var current_frame_checkbox: CheckBox = get_node(current_frame_checkbox_path)
export var plugin_checkbox_path: NodePath
onready var plugin_checkbox: CheckBox = get_node(plugin_checkbox_path)
# view settings
export var left_hand_view_checkbox_path: NodePath
onready var left_hand_view_checkbox = get_node(left_hand_view_checkbox_path)
export var right_hand_view_checkbox_path: NodePath
onready var right_hand_view_checkbox = get_node(right_hand_view_checkbox_path)
export var keypoint_view_checkbox_path: NodePath
onready var keypoint_view_checkbox = get_node(keypoint_view_checkbox_path)
export var side_keypoints_checkbox_path: NodePath
onready var side_keypoints_checkbox: CheckBox = get_node(side_keypoints_checkbox_path)
export var display_text_checkbox_path: NodePath
onready var display_text_checkbox := get_node(display_text_checkbox_path)
# display settings
export var screen_options_path: NodePath
onready var screen_options := get_node(screen_options_path)

# input settings
export var mouse_sensitivity_text_path: NodePath
onready var mouse_sensitivity_text := get_node(mouse_sensitivity_text_path)
export var mouse_sensitivity_slider_path: NodePath
onready var mouse_sensitivity_slider: HSlider = get_node(mouse_sensitivity_slider_path)
export var movement_speed_text_path: NodePath
onready var movement_speed_text := get_node(movement_speed_text_path)
export var movement_speed_slider_path: NodePath
onready var movement_speed_slider: HSlider = get_node(movement_speed_slider_path)
export var input_options_path: NodePath
onready var input_options: OptionButton = get_node(input_options_path)


func _ready():
	input_frame.max_value = (
		get_node("/root/ImportData").keypoint_data["left_hand_data"].size()
		- 1
	)
	add_button_items()


func add_button_items() -> void:
	# add items to sliders
	screen_options.add_item("Windowed")
	screen_options.add_item("Fullscreen")
	input_options.add_item("Keyboard")
	input_options.add_item("VR")


# frame settings


func _on_FPS_value_changed(value: int) -> void:
	Engine.iterations_per_second = value
	fps_text.set_text("FPS: " + str(value))


func _on_FPSMaxButton_pressed():
	Engine.iterations_per_second = 1500
	fps_text.set_text("FPS: 1500")


func _on_FPSInfo_pressed() -> void:
	pause_script.activate_popup(
		(
			"Change the frames per second (FPS) of data playback\n"
			+ "FPS can be from 1 to 90 using the slider\n"
			+ "Pressing the MAX button will set FPS to 1500"
		)
	)


func _on_InputFrame_value_changed(value: int) -> void:
	if plugin_checkbox.pressed == false:
		if value >= 0:
			hands.frame_number = value
			keypoint_view.frame_number = value

			input_frame_label.set_text("Next Frame: " + str(value))
			input_frame.value = -1
	else:
		pause_script.activate_popup("Next frame input unavailable while plugin is on")
		input_frame.value = -1


func _on_InputFrameInfo_pressed() -> void:
	pause_script.activate_popup(
		(
			"Set the next frame of data that will be shown\n"
			+ "The input field will always stay at -1"
		)
	)


func _on_PluginOptions_toggled(button_pressed: bool) -> void:
	hands.is_plugin_activated = button_pressed
	if side_keypoints_checkbox.is_pressed():
		side_keypoints_checkbox.pressed = false


func _on_PluginInfo_pressed() -> void:
	pause_script.activate_popup(
		(
			"Keypoint data will be taken from the keypoints.c file "
			+ "instead of the JSON input files"
		)
	)


func _on_CurrentFrameOptions_toggled(button_pressed: bool) -> void:
	hands.set_physics_process(not button_pressed)
	keypoint_view.set_physics_process(not button_pressed)


func _on_CurrentFrameInfo_pressed() -> void:
	pause_script.activate_popup("Pause data playback and stay on the current frame")


func _on_ResetFrameSettings_pressed():
	input_frame.value = 0
	fps_slider.value = 1
	current_frame_checkbox.pressed = false
	plugin_checkbox.pressed = false


# view settings


func _on_SideKPOptions_toggled(button_pressed: bool) -> void:
	var is_plugin_checked: bool = plugin_checkbox.is_pressed()
	if is_plugin_checked:
		keypoint_view.visible = false
		side_keypoints_checkbox.pressed = false
		pause_script.activate_popup("Side Keypoint View unavailable while plugin is on")
	else:
		keypoint_view.visible = button_pressed


func _on_SideKPInfo_pressed() -> void:
	pause_script.activate_popup(
		(
			"Show a keypoint visualization beside the hand models\n"
			+ "This is based on the data input"
		)
	)


func _on_KPOptions_toggled(button_pressed: bool) -> void:
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


func _on_KPInfo_pressed() -> void:
	pause_script.activate_popup(
		(
			"Activate keypoint visualization of the hand models\n"
			+ "Only the keypoints will be visible\n"
			+ "This is based on the hand models, not the data"
		)
	)


func _on_LeftHandView_toggled(button_pressed: bool) -> void:
	get_node("/root/Main/Hands/LeftHand").visible = button_pressed
	get_node("/root/Main/KeypointView/left_hand").visible = button_pressed


func _on_LeftHandViewInfo_pressed() -> void:
	pause_script.activate_popup("Show/hide the left hand model")


func _on_RightHandView_toggled(button_pressed: bool) -> void:
	get_node("/root/Main/Hands/RightHand").visible = button_pressed
	get_node("/root/Main/KeypointView/right_hand").visible = button_pressed


func _on_RightHandViewInfo_pressed() -> void:
	pause_script.activate_popup("Show/hide the right hand model")


func _on_DisplayTextOptions_toggled(button_pressed: bool) -> void:
	_is_dataset_text_visible = button_pressed


func _on_DisplayTextInfo_pressed() -> void:
	pause_script.activate_popup("Show/hide the text that displays the current frame")


func _on_ResetViewSettings_pressed():
	left_hand_view_checkbox.pressed = true
	right_hand_view_checkbox.pressed = false
	keypoint_view_checkbox.pressed = false
	side_keypoints_checkbox.pressed = false
	display_text_checkbox.pressed = true


# display settings


func _on_ScreenOptions_item_selected(_index: int) -> void:
	# toggle fullscreen
	OS.window_fullscreen = !OS.window_fullscreen


func _on_ScreenInfo_pressed() -> void:
	pause_script.activate_popup("Change the application to be fullscreen or windowed")


func _on_ResetDisplaySettings_pressed():
	screen_options.select(0)


# input settings


func _on_MouseSensitivity_value_changed(value: int) -> void:
	mouse_sensitivity_text.set_text("Mouse Sensitivity: " + str(value))
	controller.mouse_sensitivity = value


func _on_MouseSensitivityInfo_pressed() -> void:
	pause_script.activate_popup(
		"Change the mouse sensitivity\nThis only affects the mouse outside of the menu"
	)


func _on_MovementSpeed_value_changed(value: int) -> void:
	movement_speed_text.set_text("Movement Speed: " + str(value))
	controller.speed = value


func _on_MovementSpeedInfo_pressed() -> void:
	pause_script.activate_popup("Change the movement speed of the camera")


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
			pause_script.pause()
		else:
			# if VR doesn't initialize, switch back to keyboard mode
			pause_script.activate_popup("ERROR: Unable to initialize VR")
			input_options.select(0)
	else:
		camera.current = true


func _on_InputInfo_pressed() -> void:
	pause_script.activate_popup("Turn VR mode on or off\nThe menu is disabled in VR mode")


func _on_ResetInputSettings_pressed():
	mouse_sensitivity_slider.value = 5
	movement_speed_slider.value = 3
