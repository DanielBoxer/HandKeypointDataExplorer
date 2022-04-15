# Manages the transformation of the left and right hands based on data input.
extends Spatial

enum hands { LEFT, RIGHT }
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

onready var left_hand: Spatial = get_node("LeftHand")
onready var left_hand_skeleton: Skeleton = get_node("LeftHand/Left_Hand/Skeleton")
onready var right_hand: Spatial = get_node("RightHand")
onready var right_hand_skeleton: Skeleton = get_node("RightHand/Right_Hand/Skeleton")
var recording_frame: Dictionary setget set_recording_frame
onready var ImportData := get_node("/root/ImportData")
onready var BvhExport := get_node("/root/Main/Pause/BVHOverlay")


func _ready() -> void:
	right_hand.visible = false
	get_node("LeftHand/Left_Hand/Skeleton/Keypoints_L").visible = false
	get_node("RightHand/Right_Hand/Skeleton/Keypoints_R").visible = false
	set_physics_process(true)


func _physics_process(_delta: float) -> void:
	if left_hand.visible:
		transform_hand(hands.LEFT)
	if right_hand.visible:
		transform_hand(hands.RIGHT)


# Transforms hand mesh and hand skeleton based on data input.
func transform_hand(hand_enum: int) -> void:
	var hand: Spatial
	var hand_skeleton: Skeleton

	if hand_enum == hands.LEFT:
		hand = left_hand
		hand_skeleton = left_hand_skeleton
	else:
		hand = right_hand
		hand_skeleton = right_hand_skeleton

	# reset bone transform before calculation to remove precision errors
	hand_skeleton.set_bone_pose(keypoint_map["wrist"], Transform.IDENTITY)

	var next_frame: Dictionary = ImportData.get_keypoint_data(hand_enum)

	var data_wrist_position := f_position(next_frame, "wrist")
	var data_middle_pxm_position := f_position(next_frame, "middle_pxm")
	var data_index_pxm_position := f_position(next_frame, "index_pxm")
	var data_little_pxm_position := f_position(next_frame, "little_pxm")
	var data_middle_tip_position := f_position(next_frame, "middle_tip")

	var hand_vector_target := data_wrist_position.direction_to(data_middle_pxm_position)

	var hand_correct_vector_up := calculate_palm_direction(
		hand_vector_target,
		data_little_pxm_position,
		data_index_pxm_position,
		data_middle_tip_position,
		data_middle_pxm_position
	)

	hand.look_at(
		hand.global_transform.origin + hand_vector_target, hand_correct_vector_up
	)

	# the wrist translation moves the whole hand
	var skeleton_wrist_pose := hand_skeleton.get_bone_global_pose(keypoint_map["wrist"])
	var hand_end_position := f_position(next_frame, "wrist")
	var translated_skeleton_wrist_pose := Transform(
		skeleton_wrist_pose.basis, hand_skeleton.to_local(hand_end_position)
	)
	hand_skeleton.set_bone_global_pose_override(
		keypoint_map["wrist"], translated_skeleton_wrist_pose, 1.0, true
	)

	# if the recording is empty, that means recording is not activated
	if !recording_frame.empty():
		recording_frame[keypoint_map["wrist"]] = [
			hand_end_position, hand.global_transform.basis.get_euler()
		]

	# bones are moved from bottom to top, so the array is reversed
	var hand_keypoints := reverse_array(Array(keypoint_map.keys()))

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

			# reset bone transform before calculation to remove precision errors
			# this also makes it less likely to have a zero vector in the calculations
			hand_skeleton.set_bone_pose(
				keypoint_map[hand_keypoints[starting_joint]], Transform.IDENTITY
			)

			var hand_start_joint_pos := hand_skeleton.to_global(
				hand_skeleton.get_bone_global_pose(
					keypoint_map[hand_keypoints[starting_joint]]
				).origin
			)
			var hand_end_joint_pos := hand_skeleton.to_global(
				hand_skeleton.get_bone_global_pose(
					keypoint_map[hand_keypoints[ending_joint]]
				).origin
			)
			var data_start_joint_position := f_position(
				next_frame, hand_keypoints[starting_joint]
			)
			var data_end_joint_position := f_position(
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
			var rotation_axis_local := calculate_local_rotation_axis(
				hand_skeleton, hand_keypoints[starting_joint], rotation_axis_global
			)

			var skeleton_bone_pose := hand_skeleton.get_bone_pose(
				keypoint_map[hand_keypoints[starting_joint]]
			)
			# construct new transform with rotation
			var rotation_quat := skeleton_bone_pose.basis.get_rotation_quat()
			var new_rotation_quat := Quat(
				rotation_axis_local.normalized(), rotation_angle
			)
			var new_bone_pose := Transform(
				Basis(rotation_quat * new_rotation_quat).scaled(
					skeleton_bone_pose.basis.get_scale()
				),
				skeleton_bone_pose.origin
			)
			hand_skeleton.set_bone_pose(
				keypoint_map[hand_keypoints[starting_joint]], new_bone_pose
			)

			if !recording_frame.empty():
				var key: int = keypoint_map[hand_keypoints[starting_joint]]
				recording_frame[key] = new_bone_pose.basis.get_euler()

	if !recording_frame.empty():
		BvhExport.add_recording_frame(recording_frame)


# Returns the vector position from a Dictionary.
func f_position(frame: Dictionary, key: String) -> Vector3:
	var output_position := Vector3(frame[key][0], frame[key][1], frame[key][2])
	return output_position


# Returns a vector representing the up vector of the hand.
func calculate_palm_direction(
	hand_vector: Vector3,
	perpendicular_v1: Vector3,
	perpendicular_v2: Vector3,
	middle_tip: Vector3,
	middle_pxm: Vector3
) -> Vector3:
	# form a plane with the target vector, used for palm direction.
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


# Returns the local rotation axis of a bone.
func calculate_local_rotation_axis(
	hand_skeleton: Skeleton, keypoint: String, rotation_axis_global: Vector3
) -> Vector3:
	var bone_to_global: Transform = (
		hand_skeleton.global_transform
		* hand_skeleton.get_bone_global_pose(keypoint_map[keypoint])
	)
	var rotation_axis_local: Vector3 = (
		bone_to_global.basis.transposed()
		* rotation_axis_global
	)
	return rotation_axis_local


# Returns the input array in reverse order.
func reverse_array(input_array: Array) -> Array:
	var output_array := Array()
	for element in input_array.size():
		var current_element: String = input_array[-element - 1]
		output_array.append(current_element)
	return output_array


# Returns keypoint_map Dictionary.
func get_keypoint_map() -> Dictionary:
	return keypoint_map


func set_recording_frame(value: Dictionary) -> void:
	recording_frame = value
