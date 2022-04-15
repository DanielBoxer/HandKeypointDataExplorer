# Manages pausing and opening the menu.
extends Control

export var menu_overlay_path: NodePath
export var instructions_overlay_path: NodePath
export var settings_overlay_path: NodePath
export var popup_path: NodePath
export var popup_text_path: NodePath
export var dataset_text_path: NodePath

var _is_vr_mode_activated := false setget set_is_vr_mode_activated
var _is_dataset_text_visible := true setget set_is_dataset_text_visible

onready var menu_overlay := get_node(menu_overlay_path)
onready var instructions_overlay := get_node(instructions_overlay_path)
onready var settings_overlay := get_node(settings_overlay_path)
onready var popup := get_node(popup_path)
onready var popup_text := get_node(popup_text_path)
onready var dataset_text := get_node(dataset_text_path)
onready var FrameSettings := get_node("SettingsOverlay/Settings/Frame")
onready var ImportData := get_node("/root/ImportData")


func _ready() -> void:
	# start paused
	toggle_pause()
	popup.visible = false


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("menu") and not _is_vr_mode_activated:
		toggle_pause()


# Toggles menu and toggles pause.
func toggle_pause() -> void:
	var new_pause_state: bool = not get_tree().paused
	get_tree().paused = new_pause_state
	menu_overlay.show()
	instructions_overlay.hide()
	settings_overlay.hide()
	self.visible = new_pause_state
	popup.visible = false
	if _is_dataset_text_visible:
		dataset_text.visible = not new_pause_state
	if new_pause_state:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		FrameSettings.reset_input_frame()


# Makes information popup visible and displays input text.
func activate_popup(text: String) -> void:
	popup.visible = true
	popup_text.set_text(text)


# Hides all pause overlays
func hide_overlays() -> void:
	menu_overlay.hide()
	instructions_overlay.hide()
	settings_overlay.hide()


# Sets _is_dataset_text_visible to input state.
func set_is_dataset_text_visible(state: bool) -> void:
	_is_dataset_text_visible = state


# Sets _is_vr_mode_activated to input state.
func set_is_vr_mode_activated(state: bool) -> void:
	_is_vr_mode_activated = state


# Closes popup by hiding it.
func _on_Close_pressed():
	popup.visible = false


# Switches to the instructions menu.
func _on_Instructions_pressed() -> void:
	menu_overlay.hide()
	instructions_overlay.show()


# Switches to the settings menu.
func _on_Settings_pressed() -> void:
	menu_overlay.hide()
	settings_overlay.show()


# Toggle pause.
func _on_Unpause_pressed():
	toggle_pause()


# Reloads the current scene. This resets everything.
func _on_Restart_pressed():
	var _error_message: int = get_tree().reload_current_scene()
	# ImportData is a singleton so it doesn't get reset
	ImportData.frame_number = 0
	ImportData.is_plugin_activated = false
	toggle_pause()


# Closes the program.
func _on_Quit_pressed() -> void:
	get_tree().quit()


# Switches to the pause menu.
func _on_Back_pressed() -> void:
	menu_overlay.show()
	instructions_overlay.hide()
	settings_overlay.hide()
	popup.visible = false
