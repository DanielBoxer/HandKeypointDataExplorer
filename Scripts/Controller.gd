extends KinematicBody

export var acceleration := 6.0

var mouse_sensitivity := 0.1 setget set_mouse
var speed := 3 setget set_speed

var direction := Vector3()
var velocity := Vector3()
var movement := Vector3()

onready var controller := $Head


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _input(event: InputEvent) -> void:
	# rotate the camera by the mouse movement
	if event is InputEventMouseMotion:
		rotate_y(deg2rad(-event.relative.x * mouse_sensitivity))
		controller.rotate_x(deg2rad(-event.relative.y * mouse_sensitivity))
		controller.rotation.x = clamp(controller.rotation.x, deg2rad(-89), deg2rad(89))


func _process(delta: float) -> void:
	direction = Vector3()
	# get direction of movement based on key press
	if Input.is_action_pressed("move_forward"):
		direction -= transform.basis.z
	elif Input.is_action_pressed("move_backward"):
		direction += transform.basis.z
	if Input.is_action_pressed("move_left"):
		direction -= transform.basis.x
	elif Input.is_action_pressed("move_right"):
		direction += transform.basis.x
	if Input.is_action_pressed("move_up"):
		direction += transform.basis.y
	elif Input.is_action_pressed("move_down"):
		direction -= transform.basis.y

	# calculate movement with acceleration
	direction = direction.normalized()
	velocity = velocity.linear_interpolate(direction * speed, acceleration * delta)
	movement.z = velocity.z
	movement.x = velocity.x
	movement.y = velocity.y
	var _velocity: Vector3 = move_and_slide(movement, Vector3.UP)


func set_mouse(value: float) -> void:
	mouse_sensitivity = value * 0.02


func set_speed(value: int) -> void:
	speed = value
