# Checks if the hands are in specific poses.
extends Control

enum position { OUT, HALF, IN, X }
const names := ["Little", "Ring", "Middle", "Index", "Thumb"]
const poses := {
	# X means the position doesn't matter
	"POINTING": [position.IN, position.IN, position.IN, position.OUT, position.X],
	"OPEN": [position.OUT, position.OUT, position.OUT, position.OUT, position.OUT],
}
onready var l_path := "/root/Main/Hands/LeftHand"
onready var r_path := "/root/Main/Hands/RightHand"
onready var left_hand: Spatial = get_node(l_path)
onready var right_hand: Spatial = get_node(r_path)
onready var left_hand_skeleton: Skeleton = get_node(l_path + "/Left_Hand/Skeleton")
onready var right_hand_skeleton: Skeleton = get_node(r_path + "/Right_Hand/Skeleton")
var left_rest_distances := []
var right_rest_distances := []
var left_pose: String
var right_pose: String


func _ready():
	# get default position of hand
	left_rest_distances = calc_tip_distances(left_hand_skeleton)
	right_rest_distances = calc_tip_distances(right_hand_skeleton)
	self.set_physics_process(false)
	self.hide()


func _physics_process(_delta):
	if left_hand.visible:
		left_pose = detect_pose(left_hand_skeleton, left_rest_distances)
	else:
		left_pose = "n/a"
	if right_hand.visible:
		right_pose = detect_pose(right_hand_skeleton, right_rest_distances)
	else:
		right_pose = "n/a"
	self.text = "Left Pose: " + left_pose + "     Right Pose: " + right_pose


# Toggles visibility and physics process.
func toggle() -> void:
	var state = self.visible
	self.visible = !state
	self.set_physics_process(!state)


# Returns the current hand pose.
func detect_pose(hand_skeleton: Skeleton, rest_distances: Array) -> String:
	# the distance from the tip of the finger to the wrist determines the finger positions
	# these positions are then compared to a dictionary of poses to check for matches
	var hand_pose := []
	var bone_distances = calc_tip_distances(hand_skeleton)
	for i in range(len(bone_distances)):
		if bone_distances[i] < rest_distances[i] * 4 / 6:
			hand_pose.append(position.IN)
		elif bone_distances[i] < rest_distances[i] * 5 / 6:
			hand_pose.append(position.HALF)
		else:
			hand_pose.append(position.OUT)

	return check(hand_pose)


# Returns the distance of all finger tips to the wrist
func calc_tip_distances(hand_skeleton: Skeleton) -> Array:
	var bone_distances := []
	var wrist_position := hand_skeleton.get_bone_global_pose(0).origin
	for keypoint in names:
		var bone_id := hand_skeleton.find_bone(keypoint + "_Tip")
		var bone_position := hand_skeleton.get_bone_global_pose(bone_id).origin
		var distance := wrist_position.distance_to(bone_position)
		bone_distances.append(distance)
	return bone_distances


# Checks for a match in the pose dictionary.
func check(hand_pose: Array) -> String:
	for pose in poses.keys():
		var values: Array = poses.get(pose)
		var matches := 0
		for i in range(len(values)):
			if hand_pose[i] == values[i] || values[i] == position.X:
				matches += 1
		if matches == 5:
			return pose
	return "UNKNOWN"
