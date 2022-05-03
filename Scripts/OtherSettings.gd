# Manages the other tab in the settings menu.
extends Control

export var screen_options_path: NodePath
export var pose_checkbox_path: NodePath
onready var screen_options: OptionButton = get_node(screen_options_path)
onready var pose_checkbox: CheckBox = get_node(pose_checkbox_path)
onready var Pause := get_node("/root/Main/Pause")
onready var PoseDetection := get_node("/root/Main/Hands/DisplayContainer/PoseText")


func _ready():
	screen_options.add_item("Windowed")
	screen_options.add_item("Fullscreen")


# Toggles fullscreen.
func _on_ScreenOptions_item_selected(_index: int) -> void:
	OS.window_fullscreen = !OS.window_fullscreen


# Shows information.
func _on_ScreenInfo_pressed() -> void:
	Pause.activate_popup("Change the application to be fullscreen or windowed")


# Turns pose detection on or off.
func _on_PoseCheckBox_pressed():
	PoseDetection.toggle()


# Shows information.
func _on_PoseInfo_pressed():
	Pause.activate_popup("Activate pose detection")


# Resets all other tab settings to default value.
func _on_ResetOtherSettings_pressed():
	screen_options.select(0)
	pose_checkbox.pressed = false
