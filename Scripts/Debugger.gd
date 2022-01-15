extends Spatial

const KEYPOINTS_OFFSET := Vector3(0.25, 0, 0)

var frame_number := 0 setget set_frame_number
var debug_mode = false setget set_debug_mode
var hand_selection: Node setget set_hand_selection

var keypoint_map: Dictionary
var stored_data: Dictionary
var next_frame: Dictionary
var keypoint_number := 0
var rotation_keypoints := Array()
var hand_selection_skeleton
var hand_selection_text := "LeftHand"
var dictionary_key = "left_hand_data"

onready var left_hand := get_node("Hands/LeftHand")
onready var right_hand := get_node("Hands/RightHand")
onready var left_hand_skeleton := get_node("Hands/LeftHand/Armature/Skeleton")
onready var right_hand_skeleton := get_node("Hands/RightHand/Armature/Skeleton")
onready var debug_angle_text := get_node(
	"/root/Main/Hands/DisplayContainer/DebugAngleText"
)
onready var marker = get_node("Tools/Marker")
onready var global_axis_view := get_node("Tools/GlobalAxis")
onready var bone_axis_view := get_node("Tools/BoneAxis")
onready var left_hand_keypoints := get_node("Hands/LeftHand/Armature/Skeleton/Keypoints")
onready var right_hand_keypoints := get_node(
	"Hands/RightHand/Armature/Skeleton/Keypoints"
)
onready var tools = get_node("Tools")


func _ready() -> void:
	tools.translate(Vector3(0, -10, 0))
	keypoint_map = get_node("/root/Main/Hands").keypoint_map
	get_node("Hands").visible = false
	right_hand.visible = false
	left_hand_keypoints.visible = false
	right_hand_keypoints.visible = false
	marker.visible = false
	bone_axis_view.visible = false
	get_node("KeypointView").visible = false
	debug_angle_text.visible = false
	hand_selection = left_hand
	hand_selection_skeleton = left_hand_skeleton


func _input(event):
	if event.is_action_pressed("debug_next") and debug_mode:
		if keypoint_number < rotation_keypoints.size() - 1:
			get_rotation_information(hand_selection_skeleton)
			rotate_bone(
				hand_selection_skeleton,
				stored_data[rotation_keypoints[keypoint_number]]["axis_bone"],
				stored_data[rotation_keypoints[keypoint_number]]["angle"]
			)
			transform_marker(stored_data[rotation_keypoints[keypoint_number]]["position"])
			transform_axis(
				global_axis_view,
				stored_data[rotation_keypoints[keypoint_number]]["position"],
				stored_data[rotation_keypoints[keypoint_number]]["axis_global"]
			)
			transform_axis(
				bone_axis_view,
				stored_data[rotation_keypoints[keypoint_number]]["position"],
				stored_data[rotation_keypoints[keypoint_number]]["axis_bone"]
			)
			update_angle_text()

			keypoint_number += 1

	if event.is_action_pressed("debug_previous") and debug_mode:
		if keypoint_number > 0:
			keypoint_number -= 1
			reverse_bone_rotation(hand_selection_skeleton)
			transform_marker(stored_data[rotation_keypoints[keypoint_number]]["position"])
			transform_axis(
				global_axis_view,
				stored_data[rotation_keypoints[keypoint_number]]["position"],
				stored_data[rotation_keypoints[keypoint_number]]["axis_global"]
			)
			transform_axis(
				bone_axis_view,
				stored_data[rotation_keypoints[keypoint_number]]["position"],
				stored_data[rotation_keypoints[keypoint_number]]["axis_bone"]
			)
			update_angle_text()


func debug_new_frame_update() -> void:
	tools.translate(Vector3(0, -10, 0))
	keypoint_number = 0
	transform_hand(hand_selection, hand_selection_skeleton)
	keypoint_view()
	order_keypoint_array()
	get_node("/root/Main/Hands/DisplayContainer/DatasetText").set_text(
		"Debug: " + str(frame_number)
	)


func transform_hand(hand: Node, hand_skeleton: Node) -> void:
	var data_frames: Array = get_node("/root/ImportData").keypoint_data[dictionary_key]
	next_frame = data_frames[frame_number]
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


func order_keypoint_array() -> void:
	rotation_keypoints.clear()
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
		"index_tip",
		"middle_tip",
		"ring_tip",
		"little_tip",
	]
	for keypoint in hand_keypoints:
		if not keypoint in skipped_keypoints:
			rotation_keypoints.append(keypoint)


func get_rotation_information(hand_skeleton: Node) -> void:
	var starting_joint := keypoint_number

	# the starting joint is rotated
	# the ending joint is used to calculate the rotation values
	var ending_joint: int = starting_joint + 1

	var hand_starting_joint_position: Vector3 = hand_skeleton.to_global(
		hand_skeleton.get_bone_global_pose(
			keypoint_map[rotation_keypoints[starting_joint]]
		).origin
	)
	var hand_ending_joint_position: Vector3 = hand_skeleton.to_global(
		hand_skeleton.get_bone_global_pose(
			keypoint_map[rotation_keypoints[ending_joint]]
		).origin
	)
	var data_starting_joint_position := Vector3(
		next_frame[rotation_keypoints[starting_joint]][0],
		next_frame[rotation_keypoints[starting_joint]][1],
		next_frame[rotation_keypoints[starting_joint]][2]
	)
	var data_ending_joint_position := Vector3(
		next_frame[rotation_keypoints[ending_joint]][0],
		next_frame[rotation_keypoints[ending_joint]][1],
		next_frame[rotation_keypoints[ending_joint]][2]
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
			keypoint_map[rotation_keypoints[starting_joint]]
		)
	)
	var rotation_axis_local: Vector3 = (
		bone_to_global.basis.transposed()
		* rotation_axis_global
	)

	stored_data[rotation_keypoints[starting_joint]] = {
		"angle": rotation_angle,
		"axis_bone": rotation_axis_local,
		"axis_global": rotation_axis_global,
		"position": hand_starting_joint_position
	}


func rotate_bone(hand_skeleton: Node, rotataion_axis: Vector3, rotation_angle: float) -> void:
	var skeleton_bone_pose: Transform = hand_skeleton.get_bone_pose(
		keypoint_map[rotation_keypoints[keypoint_number]]
	)
	skeleton_bone_pose = skeleton_bone_pose.rotated(
		rotataion_axis.normalized(), rotation_angle
	)
	hand_skeleton.set_bone_pose(
		keypoint_map[rotation_keypoints[keypoint_number]], skeleton_bone_pose
	)


func reverse_bone_rotation(hand_skeleton: Node) -> void:
	var skeleton_bone_pose: Transform = hand_skeleton.get_bone_pose(
		keypoint_map[rotation_keypoints[keypoint_number]]
	)
	skeleton_bone_pose = skeleton_bone_pose.rotated(
		stored_data[rotation_keypoints[keypoint_number]]["axis_bone"].normalized(),
		-stored_data[rotation_keypoints[keypoint_number]]["angle"]
	)
	hand_skeleton.set_bone_pose(
		keypoint_map[rotation_keypoints[keypoint_number]], skeleton_bone_pose
	)


func keypoint_view() -> void:
	# this shows the keypoints beside the hand
	var keypoints := keypoint_map.keys()
	for keypoint in keypoints:
		if keypoint != "dataset":
			var position := (
				KEYPOINTS_OFFSET
				+ Vector3(
					next_frame[keypoint][0],
					next_frame[keypoint][1],
					next_frame[keypoint][2]
				)
			)
			var keypoint_node := get_node("KeypointView/" + keypoint)
			keypoint_node.global_transform.origin = position
			keypoint_node.show()


func transform_marker(position: Vector3) -> void:
	marker.global_transform.origin = position


func transform_axis(axis_node: Node, position: Vector3, axis_vector: Vector3) -> void:
	axis_node.global_transform.origin = position
	axis_node.look_at(axis_node.global_transform.origin + axis_vector, Vector3.UP)


func update_angle_text() -> void:
	debug_angle_text.set_text(
		(
			"Angle: "
			+ str(rad2deg(stored_data[rotation_keypoints[keypoint_number]]["angle"]))
			+ " degrees"
		)
	)


func set_debug_mode(state: bool) -> void:
	debug_mode = state


func set_frame_number(value: int) -> void:
	frame_number = value


func switch_hand() -> void:
	left_hand.visible = not left_hand.visible
	right_hand.visible = not right_hand.visible
	debug_new_frame_update()


func set_hand_selection(hand) -> void:
	if hand == "left":
		hand_selection = left_hand
		hand_selection_skeleton = left_hand_skeleton
		dictionary_key = "left_hand_data"
		switch_hand()
	else:
		hand_selection = right_hand
		hand_selection_skeleton = right_hand_skeleton
		dictionary_key = "right_hand_data"
		switch_hand()
