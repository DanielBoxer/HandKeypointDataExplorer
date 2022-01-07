extends Spatial

func _ready():
	# start minimized
	OS.window_fullscreen = false
	Engine.iterations_per_second = 1
