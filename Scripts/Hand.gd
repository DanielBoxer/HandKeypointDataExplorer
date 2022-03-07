extends Spatial

var keypoint_map := {
	"wrist": 0,
	"thumb_tip": 25,
	"thumb_dst": 24,
	"thumb_pxm": 23,
	"thumb_mcp": 22,
	"index_tip": 21,
	"index_dst": 20,
	"index_int": 19,
	"index_pxm": 18,
	"middle_tip": 16,
	"middle_dst": 15,
	"middle_int": 14,
	"middle_pxm": 13,
	"ring_tip": 10,
	"ring_dst": 9,
	"ring_int": 8,
	"ring_pxm": 7,
	"little_tip": 5,
	"little_dst": 4,
	"little_int": 3,
	"little_pxm": 2,
} setget , get_keypoint_map
var is_plugin_activated := false setget set_is_plugin_activated
var frame_number := 0 setget set_frame_number
var end_frame_number := 1 setget set_end_frame_number
var is_recording_activated := false setget set_is_recording_activated
var progress_bar_increase := 1.0 setget set_progress_bar_increase

onready var hand_objects := {
	"left_hand":
	{
		"hand_node": get_node("LeftHand"),
		"hand_skeleton": get_node("LeftHand/Armature/Skeleton"),
		"data_frames": Array()
	},
	"right_hand":
	{
		"hand_node": get_node("RightHand"),
		"hand_skeleton": get_node("RightHand/Armature/Skeleton"),
		"data_frames": Array()
	}
}
onready var dataset_display_text: Label = get_node("DisplayContainer/DatasetText")
onready var keypoint_data := preload("res://GDNative/bin/keypoints.gdns").new()
onready var bvh_script := get_node("/root/Main/BVH")
onready var progress_bar := get_node("/root/Main/BVH/BVHOverlay/BVHContainer/BVHBar")


func _ready() -> void:
	get_data()
	setup()
	set_physics_process(true)


func _physics_process(_delta: float) -> void:
	if get_node("LeftHand").visible:
		transform_hand("left_hand")
		if is_recording_activated && frame_number == end_frame_number:
			progress_bar.value = 0
			bvh_script.stop_recording()
		else:
			progress_bar.value += progress_bar_increase
	if get_node("RightHand").visible:
		transform_hand("right_hand")
	frame_number += 1


func setup() -> void:
	hand_objects["right_hand"]["hand_node"].visible = false
	dataset_display_text.visible = false
	dataset_display_text.set_text("Dataset: None")
	get_node("LeftHand/Armature/Skeleton/Keypoints").visible = false
	get_node("RightHand/Armature/Skeleton/Keypoints").visible = false


func get_data() -> void:
	var import_data: Dictionary = get_node("/root/ImportData").keypoint_data
	hand_objects["left_hand"]["data_frames"] = import_data["left_hand_data"]
	hand_objects["right_hand"]["data_frames"] = import_data["right_hand_data"]


func reset_frames(hand: String) -> Dictionary:
	frame_number = 0
	dataset_display_text.set_text("Dataset: " + str(frame_number))
	return hand_objects[hand]["data_frames"][0]


func calculate_palm_direction(
	hand_vector: Vector3,
	perpendicular_v1: Vector3,
	perpendicular_v2: Vector3,
	middle_tip: Vector3,
	middle_pxm: Vector3
) -> Vector3:
	# form a plane with the target vector, used for palm direction
	var hand_vector_forwards := perpendicular_v2 - perpendicular_v1
	var hand_vector_backwards := perpendicular_v1 - perpendicular_v2
	# palm is facing in the direction of either one up vector or the other
	var hand_vector_up_forwards := hand_vector.cross(hand_vector_forwards)
	var hand_vector_up_backwards := hand_vector.cross(hand_vector_backwards)
	var palm_direction := Vector3()
	# the middle tip is the keypoint most likely to be in front of the palm
	var hand_facing_direction := middle_pxm.direction_to(middle_tip)
	# find out the palm direction
	if hand_vector_up_forwards.dot(hand_facing_direction) > 0:
		palm_direction = hand_vector_up_backwards
	else:
		palm_direction = hand_vector_up_forwards
	return palm_direction


func reverse_array(input_array: Array) -> Array:
	var output_array := Array()
	for element in input_array.size():
		var current_element: String = input_array[-element - 1]
		output_array.append(current_element)
	return output_array


func f_position(frame: Dictionary, key: String) -> Vector3:
	var output_position := Vector3(frame[key][0], frame[key][1], frame[key][2])
	return output_position


func get_plugin_data(hand: String) -> Dictionary:
	dataset_display_text.set_text("Dataset: Plugin Data")
	var next_frame := Dictionary()
	# get data from plugin
	var data = keypoint_data.get_data()
	var data_length = data.size()
	var middle_index = data_length / 2
	if hand == "left_hand":
		data = data.slice(0, middle_index)
	else:
		data = data.slice(middle_index, data_length)
	var keypoint_keys = Array()
	var keypoint_values = Array()
	for key in range(0, data.size(), 2):
		keypoint_keys.append(data[key])
	for value in range(1, data.size(), 2):
		keypoint_values.append(data[value])
	for pair_num in range(data.size() / 2):
		next_frame[keypoint_keys[pair_num]] = keypoint_values[pair_num]
	return next_frame


func get_json_data(hand: String) -> Dictionary:
	var next_frame := Dictionary()
	# get data from json file
	next_frame = hand_objects[hand]["data_frames"][frame_number]
	dataset_display_text.set_text("Dataset: " + str(frame_number))
	return next_frame


func d_vector(start: Vector3, end: Vector3) -> Vector3:
	return end - start


func calculate_local_rotation_axis(
	hand: String, keypoint: String, rotation_axis_global: Vector3
) -> Vector3:
	var bone_to_global: Transform = (
		hand_objects[hand]["hand_skeleton"].global_transform
		* hand_objects[hand]["hand_skeleton"].get_bone_global_pose(keypoint_map[keypoint])
	)
	var rotation_axis_local: Vector3 = (
		bone_to_global.basis.transposed()
		* rotation_axis_global
	)
	return rotation_axis_local


func calculate_rotation_angle(vector_start: Vector3, vector_end: Vector3) -> float:
	return vector_start.angle_to(vector_end)


func calculate_global_rotation_axis(vector_start: Vector3, vector_end: Vector3) -> Vector3:
	# the axis is perpendicular to the vectors making the angle
	return vector_start.cross(vector_end)


func transform_hand(hand: String) -> void:
	var next_frame := Dictionary()
	var recording := Dictionary()
	if is_recording_activated:
		for bone in range(hand_objects["left_hand"]["hand_skeleton"].get_bone_count()):
			recording[bone] = ["0.00", "0.00", "0.00"]
	if is_plugin_activated:
		next_frame = get_plugin_data(hand)
	elif frame_number > hand_objects[hand]["data_frames"].size() - 1:
		next_frame = reset_frames(hand)
	else:
		next_frame = get_json_data(hand)

	var data_wrist_position := f_position(next_frame, "wrist")
	var data_middle_pxm_position := f_position(next_frame, "middle_pxm")
	var data_index_pxm_position := f_position(next_frame, "index_pxm")
	var data_little_pxm_position := f_position(next_frame, "little_pxm")
	var data_middle_tip_position := f_position(next_frame, "middle_tip")

	var hand_vector_target := d_vector(data_wrist_position, data_middle_pxm_position)
	var hand_correct_vector_up := calculate_palm_direction(
		hand_vector_target,
		data_little_pxm_position,
		data_index_pxm_position,
		data_middle_tip_position,
		data_middle_pxm_position
	)

	hand_objects[hand]["hand_node"].look_at(
		hand_objects[hand]["hand_node"].global_transform.origin + hand_vector_target,
		hand_correct_vector_up
	)

	# the wrist translation moves the whole hand
	var skeleton_wrist_pose: Transform
	skeleton_wrist_pose = hand_objects[hand]["hand_skeleton"].get_bone_global_pose(
		keypoint_map["wrist"]
	)
	var hand_end_position := f_position(next_frame, "wrist")
	var translated_skeleton_wrist_pose := Transform(
		skeleton_wrist_pose.basis,
		hand_objects[hand]["hand_skeleton"].to_local(hand_end_position)
	)
	hand_objects[hand]["hand_skeleton"].set_bone_global_pose_override(
		keypoint_map["wrist"], translated_skeleton_wrist_pose, 1.0, true
	)

	if is_recording_activated:
		for _i in range(6):
			recording[keypoint_map["wrist"]] = [
				"0.00", "0.00", "0.00", "0.00", "0.00", "0.00"
			]

	# bones are moved from bottom to top, so the array is reversed
	var hand_keypoints := reverse_array(Array(next_frame.keys()))

	# these values are skipped because they can't be rotated
	var skipped_keypoints := [
		"dataset",
		"wrist",
		"thumb_tip",
		"index_tip",
		"middle_tip",
		"ring_tip",
		"little_tip",
	]

	for starting_joint in hand_keypoints.size():
		if not skipped_keypoints.has(hand_keypoints[starting_joint]):
			# the starting joint is rotated
			# the ending joint is used to calculate the rotation values
			var ending_joint: int = starting_joint + 1

			var hand_start_joint_pos: Vector3
			hand_start_joint_pos = hand_objects[hand]["hand_skeleton"].to_global(
				hand_objects[hand]["hand_skeleton"].get_bone_global_pose(
					keypoint_map[hand_keypoints[starting_joint]]
				).origin
			)
			var hand_end_joint_pos: Vector3
			hand_end_joint_pos = hand_objects[hand]["hand_skeleton"].to_global(
				hand_objects[hand]["hand_skeleton"].get_bone_global_pose(
					keypoint_map[hand_keypoints[ending_joint]]
				).origin
			)
			var data_start_joint_position := f_position(
				next_frame, hand_keypoints[starting_joint]
			)
			var data_end_joint_position := f_position(
				next_frame, hand_keypoints[ending_joint]
			)

			var hand_bone_vector := d_vector(hand_start_joint_pos, hand_end_joint_pos)
			var data_bone_vector := d_vector(
				data_start_joint_position, data_end_joint_position
			)

			var rotation_angle := calculate_rotation_angle(
				hand_bone_vector, data_bone_vector
			)

			var rotation_axis_global := calculate_global_rotation_axis(
				data_bone_vector, hand_bone_vector
			)

			# axis is calculated in global space and must be converted to local
			var rotation_axis_local := calculate_local_rotation_axis(
				hand, hand_keypoints[starting_joint], rotation_axis_global
			)
			var hand_node: Spatial = hand_objects[hand]["hand_skeleton"]
			var skeleton_bone_pose: Transform = hand_node.get_bone_pose(
				keypoint_map[hand_keypoints[starting_joint]]
			)
			skeleton_bone_pose = skeleton_bone_pose.rotated(
				rotation_axis_local.normalized(), rotation_angle
			)
			hand_objects[hand]["hand_skeleton"].set_bone_pose(
				keypoint_map[hand_keypoints[starting_joint]], skeleton_bone_pose
			)
			if is_recording_activated:
				for _i in range(3):
					recording[keypoint_map[hand_keypoints[starting_joint]]] = [
						"0.00", "0.00", "0.00"
					]
	if is_recording_activated:
		bvh_script.add_data(recording)


func get_keypoint_map() -> Dictionary:
	return keypoint_map


func set_is_plugin_activated(state: bool) -> void:
	is_plugin_activated = state


func set_frame_number(value: int) -> void:
	frame_number = value


func set_is_recording_activated(state: bool) -> void:
	is_recording_activated = state


func set_end_frame_number(value: int) -> void:
	end_frame_number = value


func set_progress_bar_increase(value: float) -> void:
	progress_bar_increase = value
