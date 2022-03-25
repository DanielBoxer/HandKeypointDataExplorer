# Manages the view tab in the settings menu.
extends Control

export var left_hand_view_checkbox_path: NodePath
export var right_hand_view_checkbox_path: NodePath
export var keypoint_view_checkbox_path: NodePath
export var side_keypoints_checkbox_path: NodePath
export var display_text_checkbox_path: NodePath
onready var left_hand_view_checkbox = get_node(left_hand_view_checkbox_path)
onready var right_hand_view_checkbox = get_node(right_hand_view_checkbox_path)
onready var keypoint_view_checkbox = get_node(keypoint_view_checkbox_path)
onready var side_keypoints_checkbox: CheckBox = get_node(side_keypoints_checkbox_path)
onready var display_text_checkbox := get_node(display_text_checkbox_path)
onready var keypoint_view := get_node("/root/Main/KeypointView")

onready var Pause := get_node("/root/Main/Pause")
onready var Hand := get_node("/root/Main/Hands")


func _ready():
	pass


# Sets side_keypoints_checkbox to false.
func uncheck_side_keypoints_checkbox() -> void:
	side_keypoints_checkbox.pressed = false


# Sets the side keypoints to be visible or invisible. This appears beside the hand mesh.
func _on_SideKPOptions_toggled(button_pressed: bool) -> void:
	var is_plugin_checked: bool = Hand.get_is_plugin_activated()
	if is_plugin_checked:
		keypoint_view.visible = false
		side_keypoints_checkbox.pressed = false
		Pause.activate_popup("Side Keypoint View unavailable while plugin is on")
	else:
		keypoint_view.visible = button_pressed


# Shows information.
func _on_SideKPInfo_pressed() -> void:
	Pause.activate_popup(
		(
			"Show a keypoint visualization beside the hand models\n"
			+ "This is based on the data input"
		)
	)


# Sets the keypoints to be visible or invisible. This also hides the hand meshes.
func _on_KPOptions_toggled(button_pressed: bool) -> void:
	var hand_mesh_left: MeshInstance = get_node(
		"/root/Main/Hands/LeftHand/Left_Hand/Skeleton/Hand_Mesh_L"
	)
	var hand_keypoints_left = get_node(
		"/root/Main/Hands/LeftHand/Left_Hand/Skeleton/Keypoints_L"
	)
	hand_mesh_left.visible = not button_pressed
	hand_keypoints_left.visible = button_pressed
	var hand_mesh_right: MeshInstance = get_node(
		"/root/Main/Hands/RightHand/Right_Hand/Skeleton/Hand_Mesh_R"
	)
	var hand_keypoints_right = get_node(
		"/root/Main/Hands/RightHand/Right_Hand/Skeleton/Keypoints_R"
	)
	hand_mesh_right.visible = not button_pressed
	hand_keypoints_right.visible = button_pressed


# Shows information.
func _on_KPInfo_pressed() -> void:
	Pause.activate_popup(
		(
			"Activate keypoint visualization of the hand models\n"
			+ "Only the keypoints will be visible\n"
			+ "This is based on the hand models, not the data"
		)
	)


# Shows or hides left hand.
func _on_LeftHandView_toggled(button_pressed: bool) -> void:
	get_node("/root/Main/Hands/LeftHand").visible = button_pressed
	get_node("/root/Main/KeypointView/left_hand").visible = button_pressed


# Shows information.
func _on_LeftHandViewInfo_pressed() -> void:
	Pause.activate_popup("Show/hide the left hand model")


# Shows or hides right hand.
func _on_RightHandView_toggled(button_pressed: bool) -> void:
	get_node("/root/Main/Hands/RightHand").visible = button_pressed
	get_node("/root/Main/KeypointView/right_hand").visible = button_pressed


# Shows information.
func _on_RightHandViewInfo_pressed() -> void:
	Pause.activate_popup("Show/hide the right hand model")


# Shows or hides the frame count text.
func _on_DisplayTextOptions_toggled(button_pressed: bool) -> void:
	Pause.set_is_dataset_text_visible(button_pressed)


# Shows information.
func _on_DisplayTextInfo_pressed() -> void:
	Pause.activate_popup("Show/hide the text that displays the current frame")


# Resets all view tab settings to default values.
func _on_ResetViewSettings_pressed():
	left_hand_view_checkbox.pressed = true
	right_hand_view_checkbox.pressed = false
	keypoint_view_checkbox.pressed = false
	side_keypoints_checkbox.pressed = false
	display_text_checkbox.pressed = true
