# Exports hand animations as a .bvh file.
extends Control

onready var skeleton := get_node("/root/Main/Hands/LeftHand/Armature/Skeleton")

onready var OutputSettings := get_node("/root/Main/Pause/SettingsOverlay/Settings/Output")
onready var Pause := get_node("/root/Main/Pause")
onready var Hand := get_node("/root/Main/Hands")

var open_file_name := "" setget set_open_file_name, get_open_file_name


func _ready():
	self.visible = false


# Produces the skeleton hierarchy that appears at the start of a .bvh file.
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
	file.store_line(
		"Frames: " + str(OutputSettings.end_frame - OutputSettings.start_frame + 2)
	)
	file.store_line("Frame Time: " + str(1.0 / Engine.iterations_per_second))
	# the first frame has no rotation
	add_empty_frame(file)
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
func add_empty_frame(file: File) -> void:
	var temp := ""
	for _i in range(skeleton.get_bone_count() * 3 + 3):
		temp += "0.00 "
	file.store_line(temp)


# Adds frame of data to current open file.
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


# Returns offset between two bones.
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


# Stops adding to file and reopens menu.
func stop_recording() -> void:
	self.visible = false
	Engine.iterations_per_second = 1
	Hand.is_recording_activated = false
	Pause.toggle_pause()
	get_node("/root/Main/Pause/MenuOverlay/MenuContainer/Settings").emit_signal("pressed")


# Sets the open file to the input.
func set_open_file_name(name: String) -> void:
	open_file_name = name


# Returns the current open file.
func get_open_file_name() -> String:
	return open_file_name
