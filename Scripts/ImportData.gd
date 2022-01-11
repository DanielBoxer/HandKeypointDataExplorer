extends Node

var keypoint_data: Array setget , get_keypoint_data


func _ready() -> void:
	# get keypoint data from file
	var data_file := File.new()
	var _error_code: int = data_file.open(
		"res://Data/hand_keypoints_left.json", File.READ
	)
	var data_json: JSONParseResult = JSON.parse(data_file.get_as_text())
	data_file.close()
	var dict_data: Dictionary = data_json.result
	keypoint_data = dict_data["hand_array"]


func get_keypoint_data() -> Array:
	return keypoint_data
