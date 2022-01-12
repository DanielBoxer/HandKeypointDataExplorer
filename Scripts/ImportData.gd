extends Node

var keypoint_data: Dictionary setget , get_keypoint_data


func _ready() -> void:
	var keys := ["left_hand_data", "right_hand_data"]
	var files := {
		keys[0]: "res://Data/hand_keypoints_left.json",
		keys[1]: "res://Data/hand_keypoints_right.json"
	}
	for file_number in range(2):
		# get keypoint data from file
		var data_file := File.new()
		var _error_code: int = data_file.open(files[keys[file_number]], File.READ)
		var data_json: JSONParseResult = JSON.parse(data_file.get_as_text())
		data_file.close()
		var dict_data: Dictionary = data_json.result
		keypoint_data[keys[file_number]] = dict_data["hand_array"]


func get_keypoint_data() -> Dictionary:
	return keypoint_data
