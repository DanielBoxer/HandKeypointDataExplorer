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

var data_frames: Array
var frame_number := 0

onready var dataset_display_text := get_node("DisplayText")
onready var hand := get_node("/root/Main/LeftHand")
onready var hand_skeleton := get_node("Armature/Skeleton")


func _ready() -> void:
	data_frames = get_node("/root/ImportData").keypoint_data
	dataset_display_text.visible = false
	set_physics_process(true)


func _physics_process(_delta: float) -> void:
	if frame_number > data_frames.size() - 2:
		set_physics_process(false)
	var next_frame: Dictionary = data_frames[frame_number]
	dataset_display_text.set_text("Dataset: " + str(frame_number + 1))

	var data_wrist_position := Vector3(
		next_frame["wrist"][0], next_frame["wrist"][1], next_frame["wrist"][2]
	)
	var data_middle_pxm_position := Vector3(
		next_frame["middle_pxm"][0],
		next_frame["middle_pxm"][1],
		next_frame["middle_pxm"][2]
	)
	var data_index_pxm_position := Vector3(
		next_frame["index_pxm"][0], next_frame["index_pxm"][1], next_frame["index_pxm"][2]
	)
	var data_little_pxm_position := Vector3(
		next_frame["little_pxm"][0],
		next_frame["little_pxm"][1],
		next_frame["little_pxm"][2]
	)
	var data_middle_tip_position := Vector3(
		next_frame["middle_tip"][0],
		next_frame["middle_tip"][1],
		next_frame["middle_tip"][2]
	)

	# direction the hand is pointing
	var hand_vector_target: Vector3 = data_middle_pxm_position - data_wrist_position
	# form a plane with the target vector, used for palm direction
	var hand_vector_forwards: Vector3 = data_index_pxm_position - data_little_pxm_position
	var hand_vector_backwards: Vector3 = (
		data_little_pxm_position
		- data_index_pxm_position
	)
	# palm is facing in the direction of either one up vector or the other
	var hand_vector_up_forwards: Vector3 = hand_vector_target.cross(hand_vector_forwards)
	var hand_vector_up_backwards: Vector3 = hand_vector_target.cross(
		hand_vector_backwards
	)
	var hand_correct_vector_up := Vector3()
	# the middle tip is the keypoint most likely to be in front of the palm
	var hand_facing_direction: Vector3 = data_middle_pxm_position.direction_to(
		data_middle_tip_position
	)
	# find out the palm direction
	if hand_vector_up_forwards.dot(hand_facing_direction) > 0:
		hand_correct_vector_up = hand_vector_up_backwards
	else:
		hand_correct_vector_up = hand_vector_up_forwards
	hand.look_at(
		hand.global_transform.origin + hand_vector_target, hand_correct_vector_up
	)

	# the wrist translation moves the whole hand
	var skeleton_wrist_pose: Transform = hand_skeleton.get_bone_global_pose(
		keypoint_map["wrist"]
	)
	var hand_end_position := Vector3(
		next_frame["wrist"][0], next_frame["wrist"][1], next_frame["wrist"][2]
	)
	var translated_skeleton_wrist_pose := Transform(
		skeleton_wrist_pose.basis, hand_skeleton.to_local(hand_end_position)
	)
	hand_skeleton.set_bone_global_pose_override(
		keypoint_map["wrist"], translated_skeleton_wrist_pose, 1.0, true
	)

	var hand_keypoints_reversed := Array(next_frame.keys())
	var hand_keypoints := Array()
	# bones are moved from bottom to top, so the array is reversed
	for keypoint in hand_keypoints_reversed.size():
		var current_keypoint: String = hand_keypoints_reversed[-keypoint - 1]
		hand_keypoints.append(current_keypoint)
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

			var hand_starting_joint_position: Vector3 = hand_skeleton.to_global(
				hand_skeleton.get_bone_global_pose(
					keypoint_map[hand_keypoints[starting_joint]]
				).origin
			)
			var hand_ending_joint_position: Vector3 = hand_skeleton.to_global(
				hand_skeleton.get_bone_global_pose(
					keypoint_map[hand_keypoints[ending_joint]]
				).origin
			)
			var data_starting_joint_position := Vector3(
				next_frame[hand_keypoints[starting_joint]][0],
				next_frame[hand_keypoints[starting_joint]][1],
				next_frame[hand_keypoints[starting_joint]][2]
			)
			var data_ending_joint_position := Vector3(
				next_frame[hand_keypoints[ending_joint]][0],
				next_frame[hand_keypoints[ending_joint]][1],
				next_frame[hand_keypoints[ending_joint]][2]
			)

			var hand_bone_vector: Vector3 = (
				hand_ending_joint_position
				- hand_starting_joint_position
			)
			var data_bone_vector: Vector3 = (
				data_ending_joint_position
				- data_starting_joint_position
			)
			var rotation_angle: float = hand_bone_vector.angle_to(data_bone_vector)

			# the axis is perpendicular to the vectors making the angle
			var rotation_axis_global: Vector3 = data_bone_vector.cross(hand_bone_vector)
			# axis is calculated in global space and must be converted to local
			var bone_to_global: Transform = (
				hand_skeleton.global_transform
				* hand_skeleton.get_bone_global_pose(
					keypoint_map[hand_keypoints[starting_joint]]
				)
			)
			var rotation_axis_local: Vector3 = (
				bone_to_global.basis.transposed()
				* rotation_axis_global
			)

			var skeleton_bone_pose = hand_skeleton.get_bone_pose(
				keypoint_map[hand_keypoints[starting_joint]]
			)
			skeleton_bone_pose = skeleton_bone_pose.rotated(
				rotation_axis_local.normalized(), rotation_angle
			)
			hand_skeleton.set_bone_pose(
				keypoint_map[hand_keypoints[starting_joint]], skeleton_bone_pose
			)

	frame_number += 1


func get_keypoint_map() -> Dictionary:
	return keypoint_map
