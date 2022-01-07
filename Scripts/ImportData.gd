extends Node

var data

func _ready():
	# get keypoint data from file
	var data_file = File.new()
	data_file.open("res://Data/hand_keypoints_left.json",File.READ)
	var data_json = JSON.parse(data_file.get_as_text())
	data_file.close()
	data = data_json.result
	data = data["hand_array"]

func getData():
	return data
