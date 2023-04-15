extends Node3D


func _unhandled_input(event: InputEvent) -> void:
	## toggle fullscreen	
	## TODO: often hangs and crashes. why?
	## TODO: resizing the window also crashes
	if (event.is_action_pressed("toggle_fullscreen")):
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


func _process(delta: float) -> void:
	$Camera.rotate_y((int(delta * 1000.0) % 120_000) / 120_000.0 * 2.0 * PI)
