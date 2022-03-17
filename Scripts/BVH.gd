extends Node

var open_file_name := "" setget , get_open_file_name

var start_frame := 0
var end_frame := 0
var location := "/root/Main/Pause/SettingsOverlay/Settings/Output/Column/"

onready var bvh_button: Button = get_node(location + "BVHContainer/BVHButton")
onready var skeleton := get_node("/root/Main/Hands/LeftHand/Armature/Skeleton")
onready var pause_script := get_node("/root/Main/Pause")
onready var hand_script := get_node("/root/Main/Hands")

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
	setup()


func setup():
	self.visible = false
	var frame_count = get_node("/root/ImportData").keypoint_data["left_hand_data"].size()
	frame_start_slider.max_value = frame_count - 1
	frame_end_slider.max_value = frame_count - 1
	frame_start_input.max_value = frame_count - 1
	frame_end_input.max_value = frame_count - 1


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


func get_open_file_name() -> String:
	return open_file_name


func generate_hierarchy(file_name: String) -> void:
	var file = File.new()
	file.open(file_name, File.WRITE)
	file.store_line("HIERARCHY")
	file.store_line("ROOT " + skeleton.get_bone_name(0))
	file.store_line("{")
	file.store_line("\tOFFSET 0.00 0.00 0.00")
	file.store_line(
		"\tCHANNELS 6 Xposition Yposition Zposition Xrotation Yrotation Zrotation"
	)  # only the root has position channels

	var depth := 0

	for bone in range(1, skeleton.get_bone_count()):  # skip root
		var bone_parent = skeleton.get_bone_parent(bone)
		depth += 1
		if bone_parent != bone - 1:  # check if the bone is a new branch
			depth = end_site(file, depth)
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
			insert_tabs(depth + 1, "CHANNELS 3 Xrotation Yrotation Zrotation")
		)

	depth += 1
	depth = end_site(file, depth)

	file.store_line("}")
	file.store_line("MOTION")
	# +1 because frames are 0 indexed
	# +1 for the first frame which is all 0.00
	file.store_line("Frames: " + str(end_frame - start_frame + 2))
	file.store_line("Frame Time: " + str(1.0 / Engine.iterations_per_second))
	# the first frame has no rotation
	add_empty_frame(file)
	file.close()


func add_empty_frame(file: File) -> void:
	var temp := ""
	for _i in range(skeleton.get_bone_count() * 3 + 3):
		temp += "0.00 "
	file.store_line(temp)


func end_site(file: File, depth: int) -> int:
	file.store_line(insert_tabs(depth, "End Site"))
	file.store_line(insert_tabs(depth, "{"))
	# the tip bones are only there to get tip location so offset doesn't matter
	file.store_line(insert_tabs(depth + 1, "OFFSET 0.001 0.001 0.001"))
	for _i in range(depth - 1):
		file.store_line(insert_tabs(depth, "}"))
		depth -= 1
	file.store_line(insert_tabs(depth, "}"))
	return depth


func add_data(data: Dictionary) -> void:
	var line := ""
	for vector in data.keys():
		for element in data[vector]:
			line += element + " "
	var file = File.new()
	file.open(open_file_name, File.READ_WRITE)
	file.seek_end()
	file.store_line(line)
	file.close()


func stop_recording() -> void:
	self.visible = false
	Engine.iterations_per_second = 1
	hand_script.is_recording_activated = false
	pause_script.pause()
	get_node("/root/Main/Pause/MenuOverlay/MenuContainer/Settings").emit_signal("pressed")


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


func _on_BVH_pressed() -> void:
	self.visible = true
	var file_name: String = format_datetime()  # date time format avoids overwriting files
	var file_location := "res://Output/"
	var file_type := ".bvh"
	open_file_name = file_location + file_name + file_type
	generate_hierarchy(open_file_name)
	Engine.iterations_per_second = 1500
	hand_script.set_frame_number(start_frame)
	hand_script.set_end_frame_number(end_frame)
	hand_script.set_progress_bar_increase(100.0 / (end_frame - start_frame + 1))
	hand_script.is_recording_activated = true
	pause_script.pause()


func _on_BVHInfo_pressed() -> void:
	pause_script.activate_popup(
		(
			"Generate a .bvh file to the Output folder\n"
			+ "This file will contain armature and animation data\n"
			+ "The .bvh file can be imported to other software"
		)
	)


func _on_FrameStartSlider_value_changed(value: int) -> void:
	if value <= end_frame:
		frame_start_label.text = "Frame Start: " + str(value)
		frame_start_input.value = value
		start_frame = value
	else:
		pause_script.activate_popup("Start frame can't be greater than end frame")


func _on_FrameStartInput_value_changed(value: int) -> void:
	if value <= end_frame:
		frame_start_label.text = "Frame Start: " + str(value)
		frame_start_slider.value = value
		start_frame = value
	else:
		pause_script.activate_popup("Start frame can't be less than end frame")


func _on_FrameStartInfo_pressed() -> void:
	pause_script.activate_popup(
		(
			"Set the start frame of the .bvh file output\n"
			+ "This must be less than or equal to the end frame"
		)
	)


func _on_FrameEndSlider_value_changed(value: int) -> void:
	if value >= start_frame:
		frame_end_label.text = "Frame End: " + str(value)
		frame_end_input.value = value
		end_frame = value
	else:
		pause_script.activate_popup("End frame can't be less than start frame")


func _on_FrameEndInput_value_changed(value: int) -> void:
	if value >= start_frame:
		frame_end_label.text = "Frame End: " + str(value)
		frame_end_slider.value = value
		end_frame = value
	else:
		pause_script.activate_popup("End frame can't be greater than start frame")


func _on_FrameEndInfo_pressed() -> void:
	pause_script.activate_popup(
		(
			"Set the end frame of the .bvh file output\n"
			+ "This must be greater than or equal to the start frame"
		)
	)


func _on_LeftHandBVHInfo_pressed() -> void:
	pause_script.activate_popup("Generate a .bvh file for the left hand")


func _on_RightHandBVHInfo_pressed() -> void:
	pause_script.activate_popup("Generate a .bvh file for the right hand")


func _on_ResetBVHSettings_pressed():
	frame_start_input.value = 1
	frame_end_input.value = 1
