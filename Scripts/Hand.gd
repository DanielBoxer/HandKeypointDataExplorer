# Manages the transformation of the left and right hands based on data input.
# Most calculations are done in the HandCalculator script.
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
var is_plugin_activated := false setget set_is_plugin_activated, get_is_plugin_activated
var frame_number := 0 setget set_frame_number
var end_frame_number := 0 setget set_end_frame_number
var is_recording_activated := false setget set_is_recording_activated
var progress_bar_increase := 1.0 setget set_progress_bar_increase

onready var left_hand: Spatial = get_node("LeftHand")
onready var left_hand_skeleton: Skeleton = get_node("LeftHand/Left_Hand/Skeleton")
onready var left_hand_data := Array()
onready var right_hand: Spatial = get_node("RightHand")
onready var right_hand_skeleton: Skeleton = get_node("RightHand/Right_Hand/Skeleton")
onready var right_hand_data := Array()

onready var dataset_display_text: Label = get_node("DisplayContainer/DatasetText")
onready var keypoint_data := preload("res://GDNative/bin/keypoints.gdns").new()
onready var BvhExport := get_node("/root/Main/Pause/BVHOverlay")
onready var progress_bar: ProgressBar = get_node(
	"/root/Main/Pause/BVHOverlay/BVHContainer/BVHBar"
)


func _ready() -> void:
	get_data()
	setup()
	set_physics_process(true)


func _physics_process(_delta: float) -> void:
	if left_hand.visible:
		transform_hand(left_hand, left_hand_skeleton, left_hand_data)
	if right_hand.visible:
		transform_hand(right_hand, right_hand_skeleton, right_hand_data)
	frame_number += 1


# Called at start of program to set variables.
func setup() -> void:
	right_hand.visible = false
	dataset_display_text.visible = false
	dataset_display_text.set_text("Dataset: None")
	get_node("LeftHand/Left_Hand/Skeleton/Keypoints_L").visible = false
	get_node("RightHand/Right_Hand/Skeleton/Keypoints_R").visible = false


# Gets right and left hand data from ImportData script.
func get_data() -> void:
	var import_data: Dictionary = get_node("/root/ImportData").keypoint_data
	left_hand_data = import_data["left_hand_data"]
	right_hand_data = import_data["right_hand_data"]


# Returns the first frame of data and resets the current frame to the start.
func reset_frames(hand_data: Array) -> Dictionary:
	frame_number = 0
	dataset_display_text.set_text("Dataset: " + str(frame_number))
	return hand_data[0]


# Returns the next frame of data from the keypoints from the GDNative plugin.
func get_plugin_data(hand: Spatial) -> Dictionary:
	dataset_display_text.set_text("Dataset: Plugin Data")
	var next_frame := Dictionary()
	# get data from plugin
	var data = keypoint_data.get_data()
	var data_length = data.size()
	var middle_index = data_length / 2
	if hand == left_hand:
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


# Returns the next frame of data from the JSON file which has been converted into text.
# The data is stored in a Dictionary.
func get_json_data(hand_data: Array) -> Dictionary:
	var next_frame := Dictionary()
	# get data from dictionary
	next_frame = hand_data[frame_number]
	dataset_display_text.set_text("Dataset: " + str(frame_number))
	return next_frame


# Transforms hand mesh and hand skeleton based on data input.
func transform_hand(hand: Spatial, hand_skeleton: Skeleton, hand_data: Array) -> void:
	var next_frame := Dictionary()
	var recording := Dictionary()
	if is_recording_activated:
		for bone in range(hand_skeleton.get_bone_count()):
			recording[bone] = ["0.00", "0.00", "0.00"]
	if is_plugin_activated:
		next_frame = get_plugin_data(hand)
	elif frame_number > hand_data.size() - 1:
		next_frame = reset_frames(hand_data)
	else:
		next_frame = get_json_data(hand_data)

	var data_wrist_position := HandCalculator.f_position(next_frame, "wrist")
	var data_middle_pxm_position := HandCalculator.f_position(next_frame, "middle_pxm")
	var data_index_pxm_position := HandCalculator.f_position(next_frame, "index_pxm")
	var data_little_pxm_position := HandCalculator.f_position(next_frame, "little_pxm")
	var data_middle_tip_position := HandCalculator.f_position(next_frame, "middle_tip")

	var hand_vector_target := data_wrist_position.direction_to(data_middle_pxm_position)

	var hand_correct_vector_up := HandCalculator.calculate_palm_direction(
		hand_vector_target,
		data_little_pxm_position,
		data_index_pxm_position,
		data_middle_tip_position,
		data_middle_pxm_position
	)

	hand.look_at(
		hand.global_transform.origin + hand_vector_target, hand_correct_vector_up
	)

	var wrist_transform: Transform = hand.global_transform
	var wrist_euler: Vector3 = wrist_transform.basis.get_euler()

	# the wrist translation moves the whole hand
	var skeleton_wrist_pose: Transform
	skeleton_wrist_pose = hand_skeleton.get_bone_global_pose(keypoint_map["wrist"])
	var hand_end_position := HandCalculator.f_position(next_frame, "wrist")
	var translated_skeleton_wrist_pose := Transform(
		skeleton_wrist_pose.basis, hand_skeleton.to_local(hand_end_position)
	)
	hand_skeleton.set_bone_global_pose_override(
		keypoint_map["wrist"], translated_skeleton_wrist_pose, 1.0, true
	)

	if is_recording_activated:
		for _i in range(6):
			recording[keypoint_map["wrist"]] = [
				str(hand_end_position.x),
				str(hand_end_position.y),
				str(hand_end_position.z),
				str(rad2deg(wrist_euler.x)),
				str(rad2deg(wrist_euler.y)),
				str(rad2deg(wrist_euler.z))
			]

	# bones are moved from bottom to top, so the array is reversed
	var hand_keypoints := HandCalculator.reverse_array(Array(next_frame.keys()))

	# these values are skipped because they can't be rotated
	var skipped_keypoints := [
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
			hand_start_joint_pos = hand_skeleton.to_global(
				hand_skeleton.get_bone_global_pose(
					keypoint_map[hand_keypoints[starting_joint]]
				).origin
			)
			var hand_end_joint_pos: Vector3
			hand_end_joint_pos = hand_skeleton.to_global(
				hand_skeleton.get_bone_global_pose(
					keypoint_map[hand_keypoints[ending_joint]]
				).origin
			)
			var data_start_joint_position := HandCalculator.f_position(
				next_frame, hand_keypoints[starting_joint]
			)
			var data_end_joint_position := HandCalculator.f_position(
				next_frame, hand_keypoints[ending_joint]
			)

			var hand_bone_vector := hand_start_joint_pos.direction_to(hand_end_joint_pos)

			var data_bone_vector := data_start_joint_position.direction_to(
				data_end_joint_position
			)

			# the axis is perpendicular to the vectors making the angle
			var rotation_axis_global := data_bone_vector.cross(hand_bone_vector)

			var rotation_angle = hand_bone_vector.signed_angle_to(
				data_bone_vector, rotation_axis_global
			)

			# axis is calculated in global space and must be converted to local
			var rotation_axis_local := HandCalculator.calculate_local_rotation_axis(
				hand_skeleton,
				hand_keypoints[starting_joint],
				rotation_axis_global,
				keypoint_map
			)
			var hand_node: Spatial = hand_skeleton
			var skeleton_bone_pose: Transform = hand_node.get_bone_pose(
				keypoint_map[hand_keypoints[starting_joint]]
			)
			skeleton_bone_pose = skeleton_bone_pose.rotated(
				rotation_axis_local.normalized(), rotation_angle
			)
			hand_skeleton.set_bone_pose(
				keypoint_map[hand_keypoints[starting_joint]], skeleton_bone_pose
			)

			if is_recording_activated:
				var bone_euler: Vector3 = skeleton_bone_pose.basis.get_euler()
				for _i in range(3):
					recording[keypoint_map[hand_keypoints[starting_joint]]] = [
						str(rad2deg(bone_euler.x)),
						str(rad2deg(bone_euler.y)),
						str(rad2deg(bone_euler.z))
					]
	if is_recording_activated:
		BvhExport.add_data(recording)
		if frame_number == end_frame_number:
			progress_bar.value = 0
			BvhExport.stop_recording()
		else:
			progress_bar.value += progress_bar_increase


# Returns keypoint_map Dictionary.
func get_keypoint_map() -> Dictionary:
	return keypoint_map


# Sets is_plugin_activated to input state.
func set_is_plugin_activated(state: bool) -> void:
	is_plugin_activated = state


# Returns is_plugin_activated boolean.
func get_is_plugin_activated() -> bool:
	return is_plugin_activated


# Sets frame_number to input value.
func set_frame_number(value: int) -> void:
	frame_number = value


# Sets is_recording_activated to input state.
func set_is_recording_activated(state: bool) -> void:
	is_recording_activated = state


# Sets end_frame_number to input value.
func set_end_frame_number(value: int) -> void:
	end_frame_number = value


# Sets progress_bar_increase to input value.
func set_progress_bar_increase(value: float) -> void:
	progress_bar_increase = value


func set_left_hand_visibility(state: bool) -> void:
	left_hand.visible = state


func set_right_hand_visibility(state: bool) -> void:
	right_hand.visible = state
