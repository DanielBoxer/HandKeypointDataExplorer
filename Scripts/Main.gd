extends Spatial


func _ready() -> void:
	# start minimized
	OS.window_fullscreen = false
	# starting fps is 1
	Engine.iterations_per_second = 1
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
