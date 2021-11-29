extends KinematicBody

var speed = 10
var mouse_sensitivity = 0.1
onready var head = $Head
var direction = Vector3()
var h_acceleration = 6
var h_velocity = Vector3()
var movement = Vector3()

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	# rotate the camera by the mouse movement
	if event is InputEventMouseMotion:
		rotate_y(deg2rad(-event.relative.x * mouse_sensitivity))
		head.rotate_x(deg2rad(-event.relative.y * mouse_sensitivity))
		head.rotation.x = clamp(head.rotation.x, deg2rad(-89), deg2rad(89))
		
func _physics_process(delta):
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
	h_velocity = h_velocity.linear_interpolate(direction * speed, h_acceleration * delta)
	movement.z = h_velocity.z
	movement.x = h_velocity.x
	movement.y = h_velocity.y
	move_and_slide(movement, Vector3.UP)
