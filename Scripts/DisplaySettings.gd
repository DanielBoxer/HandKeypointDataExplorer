# Manages the display tab in the settings menu.
extends Control

export var screen_options_path: NodePath

onready var screen_options := get_node(screen_options_path)

onready var Pause := get_node("/root/Main/Pause")


func _ready():
	add_button_items()


# Adds items to sliders.
func add_button_items() -> void:
	screen_options.add_item("Windowed")
	screen_options.add_item("Fullscreen")


# Toggles fullscreen.
func _on_ScreenOptions_item_selected(_index: int) -> void:
	OS.window_fullscreen = !OS.window_fullscreen


# Shows information.
func _on_ScreenInfo_pressed() -> void:
	Pause.activate_popup("Change the application to be fullscreen or windowed")


# Resets all display tab settings to default value.
func _on_ResetDisplaySettings_pressed():
	screen_options.select(0)
