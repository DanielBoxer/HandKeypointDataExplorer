# Exports hand animations as a .bvh file.
extends Control

onready var ExportSettings := get_node("/root/Main/Pause/SettingsOverlay/Settings/Export")
onready var Pause := get_node("/root/Main/Pause")
onready var Hand := get_node("/root/Main/Hands")
onready var ImportData := get_node("/root/ImportData")
onready var progress_bar: ProgressBar = get_node(
	"/root/Main/Pause/BVHOverlay/BVHContainer/BVHBar"
)
var recording_end_frame := 0
var progress_bar_increase := 1.0
var open_file_name := ""
var frame_count := 1


func _ready():
	self.visible = false
	self.set_physics_process(false)


func _physics_process(_delta):
	if ImportData.frame_number >= recording_end_frame:
		progress_bar.value = 0
		self.stop_recording()
	else:
		progress_bar.value += progress_bar_increase


# Produces the skeleton hierarchy that appears at the start of a .bvh file.
func generate_hierarchy(
	file_name: String, skeleton: Skeleton, is_recording_end_set := true
) -> void:
	var file = File.new()
	file.open(file_name, File.WRITE)
	file.store_line("HIERARCHY")
	file.store_line("ROOT " + skeleton.get_bone_name(0))
	file.store_line("{")
	file.store_line("\tOFFSET 0 0 0")
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

		var bone_offset: Vector3 = calculate_offset(bone, bone_parent, skeleton)

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
	if is_recording_end_set:
		# +1 for the first frame which is all 0.00
		file.store_line(
			"Frames: " + str(ExportSettings.end_frame - ExportSettings.start_frame + 1)
		)
	else:
		# this line is filled with spaces because the frame count is currently unknown
		# when the frame count is added, it will overwrite this line
		# the spaces prevent it from overwriting into the next line
		# there will be some spaces left over, but that doesn't interfere with the format
		file.store_line("                                                               ")
	file.store_line("Frame Time: " + keep_point(str(1.0 / Engine.iterations_per_second)))

	# the first frame has no rotation
	add_empty_frame(file, skeleton)
	file.close()


# Returns the input string with `tab_number` tabs inserted at the beginning.
func insert_tabs(tab_number: int, input_string: String) -> String:
	var output_string := input_string
	for _i in range(tab_number):
		output_string = "\t" + output_string  # add tabs to start of string
	return output_string


# Returns the depth after ending a branch of the skeleton tree.
# Adds proper "End Site" formatting to the input file.
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


# Adds empty frame to input file.
func add_empty_frame(file: File, skeleton: Skeleton) -> void:
	var temp := ""
	for _i in range(skeleton.get_bone_count() * 3 + 3):
		temp += "0 "
	file.store_line(temp.trim_suffix(" "))


# Adds a decimal point if the input doesn't have one.
func keep_point(num: String) -> String:
	if not "." in num:
		num += ".0"
	return num


# Adds frame of data to current recording.
func add_recording_frame(frame: Dictionary) -> void:
	frame_count += 1
	var file := File.new()
	var _error_code: int = file.open(open_file_name, File.READ_WRITE)
	file.seek_end()

	var line := ""
	# the wrist contains position in addition to rotation
	line += str(frame[0][0].x) + " "
	line += str(frame[0][0].y) + " "
	line += str(frame[0][0].z) + " "
	line += str(rad2deg(frame[0][1].x)) + " "
	line += str(rad2deg(frame[0][1].y)) + " "
	line += str(rad2deg(frame[0][1].z)) + " "

	for bone in range(1, len(frame)):
		line += str(rad2deg(frame[bone].x)) + " "
		line += str(rad2deg(frame[bone].y)) + " "
		line += str(rad2deg(frame[bone].z)) + " "

	file.store_line(line.trim_suffix(" "))

	file.close()


# Returns offset between two bones.
func calculate_offset(bone_child: int, bone_parent: int, skeleton) -> Vector3:
	# get distance between two bones
	var bone_child_position = skeleton.to_global(
		skeleton.get_bone_global_pose(bone_child).origin
	)
	var bone_parent_position = skeleton.to_global(
		skeleton.get_bone_global_pose(bone_parent).origin
	)
	var bone_offset: Vector3 = bone_child_position - bone_parent_position

	return bone_offset


# Starts recording. If the `Generate BVH` button was pressed, a progress bar will show.
func start_recording(
	filename: String, skeleton: Skeleton, start_frame := -1, end_frame := -1
) -> void:
	open_file_name = filename
	frame_count = 1

	if start_frame != -1 || end_frame != -1:
		# if "Generate BVH" button is pressed
		generate_hierarchy(open_file_name, skeleton)
		Engine.iterations_per_second = 1500
		ImportData.set_frame_number(start_frame - 1)
		recording_end_frame = end_frame - 1
		progress_bar_increase = 100.0 / (end_frame - start_frame + 1)
		self.set_physics_process(true)
		self.visible = true
		Pause.toggle_pause()
		# if pause is set to visible before it's toggled, it won't work
		Pause.visible = true
		Pause.hide_overlays()
	else:
		generate_hierarchy(open_file_name, skeleton, false)

	# this tells the Hand script to start recording
	for bone in range(skeleton.get_bone_count()):
		Hand.recording_frame[bone] = Vector3.ZERO


# Adds recorded data to file and stops recording.
func stop_recording(is_recording_end_set := true) -> void:
	if is_recording_end_set:
		# if "Generate BVH" button was pressed
		Pause.toggle_pause()
		Pause.activate_popup("Recording finished")
		var settings := get_node("/root/Main/Pause/MenuOverlay/MenuContainer/Settings")
		settings.emit_signal("pressed")
		self.visible = false
		Engine.iterations_per_second = 1
		self.set_physics_process(false)
	else:
		# if recording button was pressed
		# the frame count can now be added to the file
		var file := File.new()
		var _error_code: int = file.open(open_file_name, File.READ_WRITE)
		# go to line 153
		for i in 152:
			var _line := file.get_line()
		# use `store_string` instead of `store_line` because there is already a new line
		file.store_string("Frames: " + str(frame_count))
		file.close()

	# clearing this variable tells the Hand script to stop recording
	Hand.recording_frame.clear()
