extends Node

var data
var conversionRatio

func _ready():
	# get keypoint data from file
	var data_file = File.new()
	data_file.open("res://Data/hand_keypoints_left.json",File.READ)
	var data_json = JSON.parse(data_file.get_as_text())
	data_file.close()
	data = data_json.result
	data = data["hand_array"]
	conversionRatio = conversion()

func getData():
	return {"frames": data, "ratio": conversionRatio}
	
func conversion():
	# this is to scale the keypoint data to match the hand asset
	var hand = get_node("/root/Main/LeftHand_11_26/Armature/Skeleton")
	var map = {"wrist": 0,
	"thumb_tip": 25, "thumb_dst": 24, "thumb_pxm": 23, "thumb_mcp": 22,
	"index_tip": 21, "index_dst": 20, "index_int": 19, "index_pxm": 18,
	"middle_tip": 16, "middle_dst": 15, "middle_int": 14, "middle_pxm": 13,
	"ring_tip": 10, "ring_dst": 9, "ring_int": 8, "ring_pxm": 7,
	"little_tip": 5, "little_dst": 4, "little_int": 3, "little_pxm": 2}
	
	var frame = data[1]
	var bone1 = "little_pxm"
	var bone2 = "index_pxm"
	
	# calculate the distance from two bones on the hand asset
	var little_pxm = Vector3(frame[bone1][0], frame[bone1][1], frame[bone1][2])
	var index_pxm = Vector3(frame[bone2][0], frame[bone2][1], frame[bone2][2])
	var dataVector = little_pxm - index_pxm
	dataVector = dataVector.length()
	
	# calculate the distance from the same two bones in the keypoint data
	little_pxm = hand.get_bone_global_pose(map[bone1]).origin
	index_pxm = hand.get_bone_global_pose(map[bone2]).origin
	var posVector = little_pxm - index_pxm
	posVector = posVector.length()
	
	# calculate the scaling factor
	var ratio = dataVector/posVector
	return ratio
