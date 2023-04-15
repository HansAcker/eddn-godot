extends Node3D


## Idly spin around the y axis. Press "pause" input to stop/start.
@export var idle_spin: bool = true

## Seconds per rotation.
## TODO: add configuration warning. must not be 0. negative values rotate reversed.
@export var idle_spin_speed: int = 120

# [X: (-0.939693, 0, 0.34202), Y: (0.17101, 0.866025, 0.469846), Z: (-0.296198, 0.5, -0.813797), O: (50, 50, -100)]
## Save initial camera view
@onready var camera_home: Transform3D = $Camera.transform

## TODO: could elif prevent acting on multiple keys pressed together?

func _unhandled_input(event: InputEvent) -> void:
	var handled := false

	## toggle fullscreen	
	## TODO: often hangs and crashes. also on resizing the window. why?
	if event.is_action_pressed(&"toggle_fullscreen"):
#		print(DisplayServer.window_get_mode())
#		if DisplayServer.window_get_mode() in [DisplayServer.WINDOW_MODE_MAXIMIZED, DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]:
		if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_WINDOWED:
			print("fullscreen off")
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		else:
			print("fullscreen on")
#			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
#			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

	## TODO: move camera

	if handled:
		get_viewport().set_input_as_handled()


func _unhandled_key_input(event: InputEvent) -> void:
	var handled := false

	if event.is_action_pressed(&"ui_home"):
		if event.shift_pressed:
			$Camera.transform = camera_home
		else:
			create_tween().tween_property($Camera, "transform", camera_home, 1.0)
		handled = true
	elif event.is_action_pressed(&"pause"):
		idle_spin = !idle_spin
		handled = true
	elif event.is_action_pressed(&"clear"):
		$Map/StarManager.clear()
		handled = true

	if handled:
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if idle_spin:
		$Camera.rotate_y((int(delta * 1000.0) % (idle_spin_speed * 1000)) / (idle_spin_speed * 1000.0) * 2.0 * PI)
	pass
