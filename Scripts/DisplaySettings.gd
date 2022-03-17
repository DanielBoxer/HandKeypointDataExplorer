extends Control

export var screen_options_path: NodePath

onready var screen_options := get_node(screen_options_path)

onready var pause_script := get_node("/root/Main/Pause")


func _ready():
	add_button_items()


func add_button_items() -> void:
	# add items to sliders
	screen_options.add_item("Windowed")
	screen_options.add_item("Fullscreen")


func _on_ScreenOptions_item_selected(_index: int) -> void:
	# toggle fullscreen
	OS.window_fullscreen = !OS.window_fullscreen


func _on_ScreenInfo_pressed() -> void:
	pause_script.activate_popup("Change the application to be fullscreen or windowed")


func _on_ResetDisplaySettings_pressed():
	screen_options.select(0)
