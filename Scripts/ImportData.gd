# Imports JSON data and converts to a text dictionary.
extends Node

var keypoint_data: Dictionary setget , get_keypoint_data


func _ready() -> void:
	var file_1 := "res://Data/hand_keypoints_left.json"
	var file_2 := "res://Data/hand_keypoints_right.json"
	keypoint_data["left_hand_data"] = import_data(file_1)["hand_array"]
	keypoint_data["right_hand_data"] = import_data(file_2)["hand_array"]


# Returns keypoint_data Dictionary.
func get_keypoint_data() -> Dictionary:
	return keypoint_data


# Returns a Dictionary made from a JSON file.
func import_data(file_name: String) -> Dictionary:
	# get keypoint data from file
	var data_file := File.new()
	var _error_code: int = data_file.open(file_name, File.READ)
	var data_json: JSONParseResult = JSON.parse(data_file.get_as_text())
	data_file.close()
	var dict_data: Dictionary = data_json.result
	return dict_data
