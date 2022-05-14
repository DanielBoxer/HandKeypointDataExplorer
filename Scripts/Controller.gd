# Manages camera control through mouse and keyboard input.
extends KinematicBody

var mouse_sensitivity := 0.1 setget set_mouse
var speed := 2 setget set_speed
var gravity := 9.8 setget set_gravity
var jump := 5 setget set_jump

var acceleration := 6.0
var air_acceleration := 1
var normal_acceleration := 6
var direction := Vector3()
var velocity := Vector3()
var movement := Vector3()
var is_gravity_on := false
var gravity_vector = Vector3()

onready var controller := $Head


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _input(event: InputEvent) -> void:
	# rotate the camera by the mouse movement
	if event is InputEventMouseMotion:
		rotate_y(deg2rad(-event.relative.x * mouse_sensitivity))
		controller.rotate_x(deg2rad(-event.relative.y * mouse_sensitivity))
		controller.rotation.x = clamp(controller.rotation.x, deg2rad(-89), deg2rad(89))


# _process is used here instead of _physics_process so when the FPS is changed it won't
# make the controller change speed.
func _process(delta: float) -> void:
	direction = Vector3()

	if is_gravity_on:
		# gravity
		if not is_on_floor():
			gravity_vector += Vector3.DOWN * gravity * delta
			acceleration = air_acceleration
		else:
			gravity_vector = -get_floor_normal() * gravity
			air_acceleration = normal_acceleration

		# jump
		if Input.is_action_just_pressed("jump") and is_on_floor():
			gravity_vector = Vector3.UP * jump

	# get direction of movement based on key press
	if Input.is_action_pressed("move_forward"):
		direction -= transform.basis.z
	elif Input.is_action_pressed("move_backward"):
		direction += transform.basis.z
	if Input.is_action_pressed("move_left"):
		direction -= transform.basis.x
	elif Input.is_action_pressed("move_right"):
		direction += transform.basis.x

	if not is_gravity_on:
		if Input.is_action_pressed("move_up"):
			direction += transform.basis.y
		elif Input.is_action_pressed("move_down"):
			direction -= transform.basis.y

	# calculate movement with acceleration
	direction = direction.normalized()
	velocity = velocity.linear_interpolate(direction * speed, acceleration * delta)
	movement.x = velocity.x + gravity_vector.x
	movement.y = velocity.y + gravity_vector.y
	movement.z = velocity.z + gravity_vector.z
	var _velocity: Vector3 = move_and_slide(movement, Vector3.UP)


# Toggle gravity and controller collider.
func toggle_gravity() -> void:
	var collider := get_node("ControllerCollider")
	collider.disabled = not collider.disabled
	is_gravity_on = not is_gravity_on
	gravity_vector = Vector3.ZERO


# Sets `mouse_sensitivity` to input value.
func set_mouse(value: float) -> void:
	# value is multiplied by 0.02 to allow for whole number input
	mouse_sensitivity = value * 0.02


# Sets movement speed to input value;
func set_speed(value: int) -> void:
	speed = value


func set_gravity(value: float) -> void:
	gravity = value


func set_jump(value: int) -> void:
	jump = value
