extends Spatial

const KEYPOINTS_OFFSET := Vector3(1, 0, 0)
const KEYPOINTS_SCALE_FACTOR := 1.5

var keypoints: Array
var frames: Array
var frame_number := 0


func _ready() -> void:
	visible = false
	keypoints = get_node("/root/Main/LeftHand").keypoint_map.keys()
	frames = get_node("/root/ImportData").keypoint_data


func _physics_process(_delta) -> void:
	if frame_number > frames.size() - 2:
		set_physics_process(false)
	var next_frame: Dictionary = frames[frame_number]

	# this shows the keypoints beside the hand
	if get_node("/root/Main/KeypointView").visible:
		for keypoint in keypoints:
			if keypoint != "dataset":
				var position := (
					KEYPOINTS_OFFSET
					+ Vector3(
						next_frame[keypoint][0] * KEYPOINTS_SCALE_FACTOR,
						next_frame[keypoint][1] * KEYPOINTS_SCALE_FACTOR,
						next_frame[keypoint][2] * KEYPOINTS_SCALE_FACTOR
					)
				)
				var keypoint_node := get_node("/root/Main/KeypointView/" + keypoint)
				keypoint_node.transform.origin = position
				keypoint_node.show()

	frame_number += 1
