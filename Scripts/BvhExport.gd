# Exports hand animations as a .bvh file.
extends Control

onready var OutputSettings := get_node("/root/Main/Pause/SettingsOverlay/Settings/Output")
onready var Pause := get_node("/root/Main/Pause")
onready var Hand := get_node("/root/Main/Hands")
onready var ImportData := get_node("/root/ImportData")
onready var progress_bar: ProgressBar = get_node(
	"/root/Main/Pause/BVHOverlay/BVHContainer/BVHBar"
)
var recording_end_frame := 0
var progress_bar_increase := 1.0
var open_file_name := ""


func _ready():
	self.visible = false
	set_physics_process(false)


func _physics_process(_delta):
	if ImportData.frame_number == recording_end_frame:
		progress_bar.value = 0
		stop_recording()
	else:
		progress_bar.value += progress_bar_increase


# Produces the skeleton hierarchy that appears at the start of a .bvh file.
func generate_hierarchy(file_name: String, skeleton) -> void:
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
	# +1 because frames are 0 indexed
	# +1 for the first frame which is all 0.00
	file.store_line(
		"Frames: " + str(OutputSettings.end_frame - OutputSettings.start_frame + 2)
	)
	file.store_line("Frame Time: " + str(1.0 / Engine.iterations_per_second))
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
func add_empty_frame(file: File, skeleton) -> void:
	var temp := ""
	for _i in range(skeleton.get_bone_count() * 3 + 3):
		temp += "0 "
	file.store_line(temp)


# Adds frame of data to current recording.
func add_recording_frame(frame: Dictionary) -> void:
	var file = File.new()
	file.open(open_file_name, File.READ_WRITE)
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

	file.store_line(line)

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


# Starts recording.
func start_recording(
	filename: String, skeleton: Skeleton, start_frame: int, end_frame: int
) -> void:
	open_file_name = filename
	generate_hierarchy(open_file_name, skeleton)
	Engine.iterations_per_second = 1500
	ImportData.set_frame_number(start_frame - 1)
	recording_end_frame = end_frame - 1
	progress_bar_increase = 100.0 / (end_frame - start_frame + 1)
	for bone in range(skeleton.get_bone_count()):
		Hand.recording_frame[bone] = Vector3.ZERO
	set_physics_process(true)
	Pause.toggle_pause()
	Pause.visible = true
	Pause.hide_overlays()


# Adds recorded data to file and stops recording.
func stop_recording() -> void:
	get_node("/root/Main/Pause/MenuOverlay/MenuContainer/Settings").emit_signal("pressed")
	Hand.recording_frame.clear()
	self.visible = false
	Engine.iterations_per_second = 1
	Pause.toggle_pause()
	set_physics_process(false)
