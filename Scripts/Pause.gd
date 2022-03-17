extends Control

export var menu_overlay_path: NodePath
onready var menu_overlay := get_node(menu_overlay_path)
export var instructions_overlay_path: NodePath
onready var instructions_overlay := get_node(instructions_overlay_path)
export var settings_overlay_path: NodePath
onready var settings_overlay := get_node(settings_overlay_path)
export var popup_path: NodePath
onready var popup := get_node(popup_path)
export var popup_text_path: NodePath
onready var popup_text := get_node(popup_text_path)
export var dataset_text_path: NodePath
onready var dataset_text = get_node(dataset_text_path)


func _ready() -> void:
	# start paused
	pause()
	popup.visible = false


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("menu"):  # and not _is_vr_mode_activated:
		pause()


func pause() -> void:
	# open menu and pause
	var new_pause_state: bool = not get_tree().paused
	get_tree().paused = new_pause_state
	menu_overlay.show()
	instructions_overlay.hide()
	settings_overlay.hide()
	self.visible = new_pause_state
	popup.visible = false
	# if _is_dataset_text_visible:
	# 	dataset_text.visible = not new_pause_state
	if new_pause_state:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		# input_frame_label.set_text("Next Frame: Not Set")


func activate_popup(text: String) -> void:
	popup.visible = true
	popup_text.set_text(text)


func _on_Close_pressed():
	popup.visible = false


func _on_Instructions_pressed() -> void:
	menu_overlay.hide()
	instructions_overlay.show()


func _on_Settings_pressed() -> void:
	menu_overlay.hide()
	settings_overlay.show()


func _on_Unpause_pressed():
	pause()


func _on_Restart_pressed():
	var _error_message: int = get_tree().reload_current_scene()
	pause()


func _on_Quit_pressed() -> void:
	get_tree().quit()


func _on_Back_pressed() -> void:
	menu_overlay.show()
	instructions_overlay.hide()
	settings_overlay.hide()
	popup.visible = false
