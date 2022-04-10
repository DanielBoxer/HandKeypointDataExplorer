# Manages the keypoint visualization that appears beside the hand meshes.
# This is based on the data input.
extends Spatial

const KEYPOINTS_OFFSET: Dictionary = {
	"left_hand": Vector3(0.2, 0, 0), "right_hand": Vector3(-0.2, 0, 0)
}

var keypoints: Array
var frames := {"left_hand": Array(), "right_hand": Array()}
var frame_number := 0 setget set_frame_number


func _ready() -> void:
	visible = false
	get_node("/root/Main/KeypointView/right_hand").visible = false
	keypoints = get_node("/root/Main/Hands").keypoint_map.keys()
	var import_data: Dictionary = get_node("/root/ImportData").keypoint_data
	frames["left_hand"] = import_data["left_hand_data"]
	frames["right_hand"] = import_data["right_hand_data"]


func _physics_process(_delta) -> void:
	transform_keypoints("left_hand")
	transform_keypoints("right_hand")
	frame_number += 1


# Moves keypoints to the positions specified by the data.
func transform_keypoints(hand: String) -> void:
	if frame_number > frames["left_hand"].size() - 1:
		frame_number = 0
	var next_frame: Dictionary = frames[hand][frame_number]

	# this shows the keypoints beside the hand
	for keypoint in keypoints:
		var position: Vector3 = (
			KEYPOINTS_OFFSET[hand]
			+ Vector3(
				next_frame[keypoint][0], next_frame[keypoint][1], next_frame[keypoint][2]
			)
		)
		var keypoint_node := get_node("/root/Main/KeypointView/" + hand + "/" + keypoint)
		keypoint_node.transform.origin = position
		keypoint_node.show()


# Sets `frame_number` to input value.
func set_frame_number(value: int) -> void:
	frame_number = value
