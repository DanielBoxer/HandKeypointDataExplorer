# Manages the output tab in the settings menu.
extends Control

enum hands {
	LEFT,
	RIGHT,
}

export var bvh_button_path: NodePath
export var frame_start_label_path: NodePath
export var frame_end_label_path: NodePath
export var frame_start_slider_path: NodePath
export var frame_end_slider_path: NodePath
export var frame_start_input_path: NodePath
export var frame_end_input_path: NodePath
export var bvh_overlay_path: NodePath
export var hand_bvh_option_button_path: NodePath

var start_frame := 0 setget , get_start_frame
var end_frame := 0 setget , get_end_frame
var hand_recording = hands.LEFT

onready var bvh_button: Button = get_node(bvh_button_path)
onready var frame_start_label: Label = get_node(frame_start_label_path)
onready var frame_end_label: Label = get_node(frame_end_label_path)
onready var frame_start_slider: HSlider = get_node(frame_start_slider_path)
onready var frame_end_slider: HSlider = get_node(frame_end_slider_path)
onready var frame_start_input: SpinBox = get_node(frame_start_input_path)
onready var frame_end_input: SpinBox = get_node(frame_end_input_path)
onready var bvh_overlay: ColorRect = get_node(bvh_overlay_path)
onready var hand_bvh_option_button = get_node(hand_bvh_option_button_path)
onready var left_skeleton := get_node("/root/Main/Hands/LeftHand/Left_Hand/Skeleton")
onready var right_skeleton := get_node("/root/Main/Hands/RightHand/Right_Hand/Skeleton")

onready var Pause := get_node("/root/Main/Pause")
onready var Hand := get_node("/root/Main/Hands")
onready var BvhExport := get_node("/root/Main/Pause/BVHOverlay")


func _ready():
	setup()


# Initializes starting variables.
func setup():
	var frame_count = get_node("/root/ImportData").keypoint_data["left_hand_data"].size()
	frame_start_slider.max_value = frame_count - 1
	frame_end_slider.max_value = frame_count - 1
	frame_start_input.max_value = frame_count - 1
	frame_end_input.max_value = frame_count - 1
	hand_bvh_option_button.add_item("Left Hand")
	hand_bvh_option_button.add_item("Right Hand")


# Returns starting frame of the recording.
func get_start_frame() -> int:
	return start_frame


# Returns ending frame of the recording.
func get_end_frame() -> int:
	return end_frame


# Returns the current date and time for a file name.
func format_datetime() -> String:
	var formatted: String = (
		str(OS.get_datetime().year)
		+ "_"
		+ str(OS.get_datetime().month)
		+ "_"
		+ str(OS.get_datetime().day)
		+ "_"
		+ str(OS.get_datetime().hour)
		+ "_"
		+ str(OS.get_datetime().minute)
		+ "_"
		+ str(OS.get_datetime().second)
	)
	return formatted


# Creates file and start recording.
func _on_BVH_pressed() -> void:
	var file_name: String = format_datetime()  # date time format avoids overwriting files
	var file_location := "res://Output/"
	var file_type := ".bvh"
	var file_hand: String
	var skeleton: Skeleton
	if hand_recording == hands.LEFT:
		Hand.set_left_hand_visibility(true)
		Hand.set_right_hand_visibility(false)
		file_hand = "L_"
		skeleton = left_skeleton
	else:
		Hand.set_left_hand_visibility(false)
		Hand.set_right_hand_visibility(true)
		file_hand = "R_"
		skeleton = right_skeleton
	BvhExport.open_file_name = file_location + file_hand + file_name + file_type
	BvhExport.generate_hierarchy(BvhExport.open_file_name, skeleton)
	Engine.iterations_per_second = 1500
	Hand.set_frame_number(start_frame)
	Hand.set_end_frame_number(end_frame)
	Hand.set_progress_bar_increase(100.0 / (end_frame - start_frame + 1))
	Hand.is_recording_activated = true
	Pause.toggle_pause()
	Pause.visible = true
	Pause.hide_overlays()
	bvh_overlay.visible = true


# Shows information.
func _on_BVHInfo_pressed() -> void:
	Pause.activate_popup(
		(
			"Generate a .bvh file to the Output folder\n"
			+ "This file will contain armature and animation data\n"
			+ "The .bvh file can be imported to other software"
		)
	)


# Sets frame start to input value.
func _on_FrameStartSlider_value_changed(value: int) -> void:
	if value <= end_frame:
		frame_start_label.text = "Frame Start: " + str(value)
		frame_start_input.value = value
		start_frame = value
	else:
		Pause.activate_popup("Start frame can't be greater than end frame")


# Sets frame start to input value.
func _on_FrameStartInput_value_changed(value: int) -> void:
	if value <= end_frame:
		frame_start_label.text = "Frame Start: " + str(value)
		frame_start_slider.value = value
		start_frame = value
	else:
		Pause.activate_popup("Start frame can't be less than end frame")


# Shows information.
func _on_FrameStartInfo_pressed() -> void:
	Pause.activate_popup(
		(
			"Set the start frame of the .bvh file output\n"
			+ "This must be less than or equal to the end frame"
		)
	)


# Sets frame end to input value.
func _on_FrameEndSlider_value_changed(value: int) -> void:
	if value >= start_frame:
		frame_end_label.text = "Frame End: " + str(value)
		frame_end_input.value = value
		end_frame = value
	else:
		Pause.activate_popup("End frame can't be less than start frame")


# Sets frame end to input value.
func _on_FrameEndInput_value_changed(value: int) -> void:
	if value >= start_frame:
		frame_end_label.text = "Frame End: " + str(value)
		frame_end_slider.value = value
		end_frame = value
	else:
		Pause.activate_popup("End frame can't be greater than start frame")


# Shows information.
func _on_FrameEndInfo_pressed() -> void:
	Pause.activate_popup(
		(
			"Set the end frame of the .bvh file output\n"
			+ "This must be greater than or equal to the start frame"
		)
	)


# Resets all output tab settings to default value.
func _on_ResetBVHSettings_pressed():
	frame_start_input.value = 1
	frame_end_input.value = 1


func _on_HandBVHOptionButton_item_selected(index):
	if index == 0:
		hand_recording = hands.LEFT
	else:
		hand_recording = hands.RIGHT
