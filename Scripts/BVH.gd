extends Node

var location := "/root/Main/Pause/SettingsOverlay/Settings/BVHSettings/Column/"
onready var bvh_button: Button = get_node(location + "BVHButton")
onready var skeleton := get_node("/root/Main/Hands/LeftHand/Armature/Skeleton")
onready var pause = get_node("/root/Main/Pause")

onready var frame_start_label: Label = get_node(
	location + "FrameStartContainer/FrameStartLabel"
)
onready var frame_end_label: Label = get_node(
	location + "FrameEndContainer/FrameEndLabel"
)
onready var frame_start_slider: HSlider = get_node(
	location + "FrameStartContainer/FrameStartSlider"
)
onready var frame_end_slider: HSlider = get_node(
	location + "FrameEndContainer/FrameEndSlider"
)
onready var frame_start_input: SpinBox = get_node(
	location + "FrameStartContainer/FrameStartInput"
)
onready var frame_end_input: SpinBox = get_node(
	location + "FrameEndContainer/FrameEndInput"
)


func _ready():
	var frame_count = get_node("/root/ImportData").keypoint_data["left_hand_data"].size()

	frame_start_slider.max_value = frame_count
	frame_end_slider.max_value = frame_count
	frame_start_input.max_value = frame_count
	frame_end_input.max_value = frame_count


func insert_tabs(tab_number: int, input_string: String) -> String:
	var output_string := input_string
	for _i in range(tab_number):
		output_string = "\t" + output_string  # add tabs to start of string
	return output_string


func calculate_offset(bone_child: int, bone_parent: int) -> Vector3:
	# get distance between two bones
	var bone_child_position = skeleton.to_global(
		skeleton.get_bone_global_pose(bone_child).origin
	)
	var bone_parent_position = skeleton.to_global(
		skeleton.get_bone_global_pose(bone_parent).origin
	)
	var bone_offset: Vector3 = bone_child_position - bone_parent_position

	return bone_offset


func _on_BVH_pressed() -> void:
	var file = File.new()
	var file_name: String = (
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
	)  # date time format avoids overwriting files
	var file_location := "res://Output/"
	var file_type := ".bvh"
	file.open(file_location + file_name + file_type, File.WRITE)

	file.store_line("HIERARCHY")
	file.store_line("ROOT " + skeleton.get_bone_name(0))
	file.store_line("{")
	file.store_line("\tOFFSET 0.00 0.00 0.00")
	file.store_line(
		"\tCHANNELS 6 Xposition Yposition Zposition Zrotation Xrotation Yrotation"
	)  # only the root has position channels

	var depth := 0

	for bone in range(1, skeleton.get_bone_count()):  # skip root
		var bone_parent = skeleton.get_bone_parent(bone)
		depth += 1
		if bone_parent != bone - 1:  # check if the bone is a new branch
			file.store_line(insert_tabs(depth, "End Site"))
			file.store_line(insert_tabs(depth, "{"))
			# the tip bones are only there to get tip location so offset doesn't matter
			file.store_line(insert_tabs(depth + 1, "OFFSET 0.001 0.001 0.001"))
			for _i in range(depth - 1):
				file.store_line(insert_tabs(depth, "}"))
				depth -= 1
			file.store_line(insert_tabs(depth, "}"))
		file.store_line(insert_tabs(depth, "Joint " + skeleton.get_bone_name(bone)))
		file.store_line(insert_tabs(depth, "{"))

		var bone_offset: Vector3 = calculate_offset(bone, bone_parent)

		file.store_line(
			insert_tabs(
				depth + 1,
				(
					"OFFSET "
					+ str(bone_offset.x)
					+ " "
					+ str(bone_offset.y)
					+ " "
					+ str(bone_offset.z)
				)
			)
		)
		file.store_line(
			insert_tabs(depth + 1, "CHANNELS 3 Zrotation Xrotation Yrotation")
		)

	depth += 1
	file.store_line(insert_tabs(depth, "End Site"))
	file.store_line(insert_tabs(depth, "{"))
	file.store_line(insert_tabs(depth + 1, "OFFSET 0.001 0.001 0.001"))
	for _i in range(depth - 1):
		file.store_line(insert_tabs(depth, "}"))
		depth -= 1
	file.store_line(insert_tabs(depth, "}"))

	file.store_line("}")
	file.store_line("MOTION")
	file.store_line("Frames: 1")
	file.store_line("Frame Time: 0.033333")

	var temp := ""
	for _i in range(skeleton.get_bone_count() * 3 + 3):
		temp += "0.00 "
	file.store_line(temp)

	file.close()


func _on_FrameStartSlider_value_changed(value: int) -> void:
	if value <= frame_end_slider.value:
		frame_start_label.text = "Frame Start: " + str(value)
		frame_start_input.value = value
	else:
		pause.activate_popup("Start frame can't be greater than end frame")


func _on_FrameEndSlider_value_changed(value: int) -> void:
	if value >= frame_start_slider.value:
		frame_end_label.text = "Frame End: " + str(value)
		frame_end_input.value = value
	else:
		pause.activate_popup("End frame can't be less than start frame")


func _on_FrameStartInput_value_changed(value: int) -> void:
	if value <= frame_end_input.value:
		frame_start_label.text = "Frame Start: " + str(value)
		frame_start_slider.value = value
	else:
		pause.activate_popup("Start frame can't be less than end frame")


func _on_FrameEndInput_value_changed(value: int) -> void:
	if value >= frame_start_input.value:
		frame_end_label.text = "Frame End: " + str(value)
		frame_end_slider.value = value
	else:
		pause.activate_popup("End frame can't be greater than start frame")
