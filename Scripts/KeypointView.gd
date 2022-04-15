# Manages the keypoint visualization that appears beside the hand meshes.
# This is based on the data input.
extends Spatial

enum hands { LEFT, RIGHT }
const KEYPOINTS_OFFSET: Dictionary = {
	hands.LEFT: Vector3(0.2, 0, 0), hands.RIGHT: Vector3(-0.2, 0, 0)
}
var path := "/root/Main/KeypointView"
onready var left_keypoints := get_node(path + "/0")
onready var right_keypoints := get_node(path + "/1")
var keypoints := Array()
onready var ImportData = get_node("/root/ImportData")
onready var Hand := get_node("/root/Main/Hands")


func _ready() -> void:
	keypoints = Hand.keypoint_map.keys()
	right_keypoints.visible = false
	visible = false
	set_physics_process(false)


func _physics_process(_delta) -> void:
	if left_keypoints.visible:
		transform_keypoints(hands.LEFT)
	if right_keypoints.visible:
		transform_keypoints(hands.RIGHT)


# Moves keypoints to the positions specified by the data.
func transform_keypoints(hand_enum: int) -> void:
	var next_frame: Dictionary = ImportData.get_keypoint_data(hand_enum)
	# this shows the keypoints beside the hand
	for keypoint in keypoints:
		var position: Vector3 = (
			KEYPOINTS_OFFSET[hand_enum]
			+ Hand.f_position(next_frame, keypoint)
		)
		var keypoint_node := get_node(path + "/" + str(hand_enum) + "/" + keypoint)
		keypoint_node.transform.origin = position
		keypoint_node.show()
