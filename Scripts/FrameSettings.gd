extends Control

export var input_frame_label_path: NodePath
export var input_frame_path: NodePath
export var fps_text_path: NodePath
export var fps_slider_path: NodePath
export var current_frame_checkbox_path: NodePath
export var plugin_checkbox_path: NodePath

onready var input_frame_label := get_node(input_frame_label_path)
onready var input_frame: SpinBox = get_node(input_frame_path)
onready var fps_text: Label = get_node(fps_text_path)
onready var fps_slider := get_node(fps_slider_path)
onready var current_frame_checkbox: CheckBox = get_node(current_frame_checkbox_path)
onready var plugin_checkbox: CheckBox = get_node(plugin_checkbox_path)

onready var Pause := get_node("/root/Main/Pause")
onready var keypoint_view := get_node("/root/Main/KeypointView")
onready var Hand := get_node("/root/Main/Hands")
onready var ViewSettings := get_node("/root/Main/Pause/SettingsOverlay/Settings/View")


func _ready():
	input_frame.max_value = (
		get_node("/root/ImportData").keypoint_data["left_hand_data"].size()
		- 1
	)


func reset_input_frame() -> void:
	input_frame_label.set_text("Next Frame: Not Set")


func _on_FPS_value_changed(value: int) -> void:
	Engine.iterations_per_second = value
	fps_text.set_text("FPS: " + str(value))


func _on_FPSMaxButton_pressed():
	Engine.iterations_per_second = 1500
	fps_text.set_text("FPS: 1500")


func _on_FPSInfo_pressed() -> void:
	Pause.activate_popup(
		(
			"Change the frames per second (FPS) of data playback\n"
			+ "FPS can be from 1 to 90 using the slider\n"
			+ "Pressing the MAX button will set FPS to 1500"
		)
	)


func _on_InputFrame_value_changed(value: int) -> void:
	if plugin_checkbox.pressed == false:
		if value >= 0:
			Hand.frame_number = value
			keypoint_view.frame_number = value

			input_frame_label.set_text("Next Frame: " + str(value))
			input_frame.value = -1
	else:
		Pause.activate_popup("Next frame input unavailable while plugin is on")
		input_frame.value = -1


func _on_InputFrameInfo_pressed() -> void:
	Pause.activate_popup(
		(
			"Set the next frame of data that will be shown\n"
			+ "The input field will always stay at -1"
		)
	)


func _on_PluginOptions_toggled(button_pressed: bool) -> void:
	Hand.is_plugin_activated = button_pressed
	ViewSettings.uncheck_side_keypoints_checkbox()


func _on_PluginInfo_pressed() -> void:
	Pause.activate_popup(
		(
			"Keypoint data will be taken from the keypoints.c file "
			+ "instead of the JSON input files"
		)
	)


func _on_CurrentFrameOptions_toggled(button_pressed: bool) -> void:
	Hand.set_physics_process(not button_pressed)
	keypoint_view.set_physics_process(not button_pressed)


func _on_CurrentFrameInfo_pressed() -> void:
	Pause.activate_popup("Pause data playback and stay on the current frame")


func _on_ResetFrameSettings_pressed():
	input_frame.value = 0
	fps_slider.value = 1
	current_frame_checkbox.pressed = false
	plugin_checkbox.pressed = false
