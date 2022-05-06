# Manages the other tab in the settings menu.
extends Control

export var screen_options_path: NodePath
export var pose_checkbox_path: NodePath
export var amount_spinbox_path: NodePath
export var location_checkbox_path: NodePath
export var size_checkbox_path: NodePath
onready var screen_options: OptionButton = get_node(screen_options_path)
onready var pose_checkbox: CheckBox = get_node(pose_checkbox_path)
onready var amount_spinbox: SpinBox = get_node(amount_spinbox_path)
onready var location_checkbox: CheckBox = get_node(location_checkbox_path)
onready var size_checkbox: CheckBox = get_node(size_checkbox_path)
onready var Pause := get_node("/root/Main/Pause")
onready var PoseDetection := get_node("/root/Main/Hands/DisplayContainer/PoseText")
onready var CreateObjects := get_node("/root/Main/Objects")
var is_cube_location_random := false
var is_cube_size_random := false
var cube_amount := 1


func _ready():
	screen_options.add_item("Windowed")
	screen_options.add_item("Fullscreen")


# Toggles fullscreen.
func _on_ScreenOptions_item_selected(index: int) -> void:
	if index == 0:
		OS.window_fullscreen = false
	else:
		OS.window_fullscreen = true


# Shows information.
func _on_ScreenInfo_pressed() -> void:
	Pause.activate_popup("Change the application to be fullscreen or windowed")


# Turns pose detection on or off.
func _on_PoseCheckBox_pressed():
	PoseDetection.toggle()


# Shows information.
func _on_PoseInfo_pressed():
	Pause.activate_popup("Activate pose detection")


# Creates cubes and sets FPS to 60.
func _on_CubeButton_pressed():
	CreateObjects.create_cubes(cube_amount, is_cube_location_random, is_cube_size_random)
	Engine.iterations_per_second = 60
	var fps_text = get_node(
		"/root/Main/Pause/SettingsOverlay/Settings/Frame/Column/FPSContainer/FPSValue"
	)
	fps_text.set_text("FPS: 60")


func _on_DeleteCubeButton_pressed():
	CreateObjects.delete_cubes()


func _on_CubeInfo_pressed():
	Pause.activate_popup(
		(
			"Press 'Create Cubes' to create interactable cubes."
			+ "\nAfter creating, FPS will be set to 60 for accurate physics."
			+ "\nPress 'Delete Cubes' to delete all cubes"
		)
	)


func _on_AmountSpinBox_value_changed(value):
	cube_amount = value


func _on_LocationCheckBox_pressed():
	is_cube_location_random = !is_cube_location_random


func _on_SizeCheckBox_pressed():
	is_cube_size_random = !is_cube_size_random


func _on_RandomInfo_pressed():
	Pause.activate_popup(
		(
			"Enter the amount of cubes to create."
			+ "\nRandomize the cubes starting location or size"
		)
	)


# Resets all other tab settings to default value.
func _on_ResetOtherSettings_pressed():
	screen_options.select(0)
	screen_options.emit_signal("item_selected", 0)
	pose_checkbox.pressed = false
	pose_checkbox.emit_signal("pressed")
	amount_spinbox.value = 1
	location_checkbox.pressed = false
	size_checkbox.pressed = false
