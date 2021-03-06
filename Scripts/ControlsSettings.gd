# Manages the input tab in the settings menu.
extends Control

export var mouse_sensitivity_text_path: NodePath
export var mouse_sensitivity_slider_path: NodePath
export var movement_speed_text_path: NodePath
export var movement_speed_slider_path: NodePath
export var gravity_label_path: NodePath
export var gravity_checkbox_path: NodePath
export var gravity_slider_path: NodePath
export var jump_label_path: NodePath
export var jump_slider_path: NodePath
export var input_options_path: NodePath
export var screen_options_path: NodePath

onready var mouse_sensitivity_text: Label = get_node(mouse_sensitivity_text_path)
onready var mouse_sensitivity_slider: HSlider = get_node(mouse_sensitivity_slider_path)
onready var movement_speed_text: Label = get_node(movement_speed_text_path)
onready var movement_speed_slider: HSlider = get_node(movement_speed_slider_path)
onready var gravity_label: Label = get_node(gravity_label_path)
onready var gravity_checkbox: CheckBox = get_node(gravity_checkbox_path)
onready var gravity_slider: HSlider = get_node(gravity_slider_path)
onready var jump_label: Label = get_node(jump_label_path)
onready var jump_slider: HSlider = get_node(jump_slider_path)
onready var input_options: OptionButton = get_node(input_options_path)
onready var screen_options: OptionButton = get_node(screen_options_path)

onready var Pause := get_node("/root/Main/Pause")
onready var Controller := get_node("/root/Main/Controller")


func _ready():
	input_options.add_item("Keyboard")
	input_options.add_item("VR")
	screen_options.add_item("Windowed")
	screen_options.add_item("Fullscreen")


# Sets mouse sensitivity to input value.
func _on_MouseSensitivity_value_changed(value: int) -> void:
	mouse_sensitivity_text.set_text("Mouse Sensitivity: " + str(value))
	Controller.mouse_sensitivity = value


# Shows information.
func _on_MouseSensitivityInfo_pressed() -> void:
	Pause.activate_popup(
		"Change the mouse sensitivity\nThis only affects the mouse outside of the menu"
	)


# Sets movement speed to input value.
func _on_MovementSpeed_value_changed(value: int) -> void:
	movement_speed_text.set_text("Movement Speed: " + str(value))
	Controller.speed = value


# Shows information.
func _on_MovementSpeedInfo_pressed() -> void:
	Pause.activate_popup("Change the movement speed of the camera")


func _on_GravityCheckBox_toggled(_button_pressed: bool) -> void:
	Controller.toggle_gravity()


func _on_GravitySlider_value_changed(value: float) -> void:
	gravity_label.text = "Gravity: " + str(value)
	Controller.gravity = value


func _on_GravityInfo_pressed() -> void:
	Pause.activate_popup(
		(
			"Toggle gravity and controller collider."
			+ "\nUse the slider to change the strength of gravity"
		)
	)


func _on_JumpSlider_value_changed(value: int) -> void:
	jump_label.text = "Jump: " + str(value)
	Controller.jump = value


func _on_JumpInfo_pressed() -> void:
	Pause.activate_popup(
		(
			"Change the amount the controller will move up when jumping."
			+ "\nJumping is disabled when gravity is off"
		)
	)


# Switches to VR mode.
func _on_InputOptions_item_selected(_index: int) -> void:
	var camera: Camera = get_node("/root/Main/Controller/Head/Camera")
	var vr_camera: ARVRCamera = get_node("/root/Main/Objects/ARVROrigin/ARVRCamera")
	if camera.current:
		# start VR
		var VR: ARVRInterface = ARVRServer.find_interface("OpenVR")
		if VR and VR.initialize():
			vr_camera.current = true
			get_viewport().arvr = true
			get_viewport().hdr = false
			OS.vsync_enabled = false
			Engine.target_fps = 90
			Pause._is_vr_mode_activated = true
			Pause.pause()
		else:
			# if VR doesn't initialize, switch back to keyboard mode
			Pause.activate_popup("ERROR: Unable to initialize VR")
			input_options.select(0)
	else:
		camera.current = true


# Shows information.
func _on_InputInfo_pressed() -> void:
	Pause.activate_popup("Turn VR mode on or off\nThe menu is disabled in VR mode")


# Toggles fullscreen.
func _on_ScreenOptions_item_selected(index: int) -> void:
	if index == 0:
		OS.window_fullscreen = false
	else:
		OS.window_fullscreen = true


# Shows information.
func _on_ScreenInfo_pressed() -> void:
	Pause.activate_popup("Change the application to be fullscreen or windowed")


# Resets all input tab settings to default values.
func _on_ResetInputSettings_pressed():
	mouse_sensitivity_slider.value = 5
	movement_speed_slider.value = 2
	screen_options.select(0)
	screen_options.emit_signal("item_selected", 0)
	gravity_checkbox.pressed = false
	gravity_slider.value = 9.8
	jump_slider.value = 5
