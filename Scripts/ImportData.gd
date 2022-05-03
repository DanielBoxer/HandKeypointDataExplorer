# Imports JSON data and converts to a text dictionary. The Hand script gets data from this
# script every frame.
extends Node

enum hands { LEFT, RIGHT }
var is_plugin_activated := false setget set_is_plugin_activated, get_is_plugin_activated
var left_hand_data := Array()
var right_hand_data := Array()
# frame_number starts at -1 because it will be incremented immediately to 0
var frame_number := -1 setget set_frame_number
onready var Hand := get_node("/root/Main/Hands")
onready var keypoint_data := preload("res://GDNative/bin/keypoints.gdns").new()


func _ready() -> void:
	var file_1 := "res://Data/hand_keypoints_left.json"
	var file_2 := "res://Data/hand_keypoints_right.json"
	left_hand_data = import_data(file_1)["hand_array"]
	right_hand_data = import_data(file_2)["hand_array"]


func _physics_process(_delta):
	frame_number += 1


# Returns keypoint_data.
func get_keypoint_data(hand: int) -> Dictionary:
	var next_frame := Dictionary()
	var hand_data = Array()
	if hand == hands.LEFT:
		hand_data = left_hand_data
	else:
		hand_data = right_hand_data

	if is_plugin_activated:
		next_frame = get_plugin_data(hand)
	else:
		if frame_number > hand_data.size() - 1:
			frame_number = 0
		next_frame = get_json_data(hand_data)
	return next_frame


# Gets right and left hand data from ImportData script.
func get_data() -> void:
	var import_data: Dictionary = get_node("/root/ImportData").keypoint_data
	left_hand_data = import_data["left_hand_data"]
	right_hand_data = import_data["right_hand_data"]


# Returns a Dictionary made from a JSON file.
func import_data(file_name: String) -> Dictionary:
	# get keypoint data from file
	var data_file := File.new()
	var _error_code: int = data_file.open(file_name, File.READ)
	var data_json: JSONParseResult = JSON.parse(data_file.get_as_text())
	data_file.close()
	var dict_data: Dictionary = data_json.result
	return dict_data


# Returns the next frame of data from the JSON file which has been converted into text.
# The data is stored in a Dictionary.
func get_json_data(hand_data: Array) -> Dictionary:
	var next_frame := Dictionary()
	# get data from dictionary
	next_frame = hand_data[frame_number]
	get_node("/root/Main/Hands/DisplayContainer/DatasetText").set_text(
		"Dataset: " + str(frame_number)
	)
	return next_frame


# Returns the next frame of data from the keypoints from the GDNative plugin.
func get_plugin_data(hand: int) -> Dictionary:
	get_node("/root/Main/Hands/DisplayContainer/DatasetText").set_text(
		"Dataset: Plugin Data"
	)
	var next_frame := Dictionary()
	# get data from plugin
	var data = keypoint_data.get_data()
	var data_length = data.size()
	var middle_index = data_length / 2
	if hand == hands.LEFT:
		data = data.slice(0, middle_index)
	else:
		data = data.slice(middle_index, data_length)
	var keypoint_keys = Array()
	var keypoint_values = Array()
	for key in range(0, data.size(), 2):
		keypoint_keys.append(data[key])
	for value in range(1, data.size(), 2):
		keypoint_values.append(data[value])
	for pair_num in range(data.size() / 2):
		next_frame[keypoint_keys[pair_num]] = keypoint_values[pair_num]
	return next_frame


# Returns size of data.
func get_data_size() -> int:
	return left_hand_data.size()


# Sets frame_number to input value.
func set_frame_number(value: int) -> void:
	frame_number = value


# Sets is_plugin_activated to input state.
func set_is_plugin_activated(state: bool) -> void:
	is_plugin_activated = state


# Returns is_plugin_activated boolean.
func get_is_plugin_activated() -> bool:
	return is_plugin_activated
