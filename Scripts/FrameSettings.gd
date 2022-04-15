# Manages the frame tab in the settings menu.
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
onready var ImportData := get_node("/root/ImportData")


func _ready():
	input_frame.max_value = ImportData.get_data_size() - 1


# Resets input frame text.
func reset_input_frame() -> void:
	input_frame_label.set_text("Next Frame: Not Set")


# Sets FPS to input value.
func _on_FPS_value_changed(value: int) -> void:
	Engine.iterations_per_second = value
	fps_text.set_text("FPS: " + str(value))


# Changes FPS to 1500.
func _on_FPSMaxButton_pressed():
	Engine.iterations_per_second = 1500
	fps_text.set_text("FPS: 1500")


# Shows information.
func _on_FPSInfo_pressed() -> void:
	Pause.activate_popup(
		(
			"Change the frames per second (FPS) of data playback\n"
			+ "FPS can be from 1 to 90 using the slider\n"
			+ "Pressing the MAX button will set FPS to 1500"
		)
	)


# Sets next frame of data.
func _on_InputFrame_value_changed(value: int) -> void:
	ImportData.frame_number = value - 1
	input_frame_label.set_text("Next Frame: " + str(value))


# Shows information.
func _on_InputFrameInfo_pressed() -> void:
	Pause.activate_popup("Set the next frame of data that will be shown\n")


# Turns plugin data on.
func _on_PluginOptions_toggled(button_pressed: bool) -> void:
	ImportData.is_plugin_activated = button_pressed


# Shows information.
func _on_PluginInfo_pressed() -> void:
	Pause.activate_popup(
		(
			"Keypoint data will be taken from the keypoints.c file "
			+ "instead of the JSON input files"
		)
	)


# Stops `_physics_process` in Hand script which makes it stay on the current frame.
func _on_CurrentFrameOptions_toggled(button_pressed: bool) -> void:
	Hand.set_physics_process(not button_pressed)
	keypoint_view.set_physics_process(not button_pressed)


# Shows information.
func _on_CurrentFrameInfo_pressed() -> void:
	Pause.activate_popup("Pause data playback and stay on the current frame")


# Resets all frame tab settings to default value.
func _on_ResetFrameSettings_pressed():
	input_frame.value = 0
	fps_slider.value = 1
	current_frame_checkbox.pressed = false
	plugin_checkbox.pressed = false
