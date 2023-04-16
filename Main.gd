extends Node3D


## TODO: explain why which input is handled where


## Idly spin around the y axis. Press "pause" input to stop/start.
@export var idle_spin: bool = true

## Seconds per rotation.
## TODO: add configuration warning. must not be 0. negative values rotate clockwise.
@export var idle_spin_speed: int = 120

## Camera movement speed in ly/s
@export var camera_movement_speed : float = 100.0

## Camera movement speed factor when shift key pressed.
#@export var camera_movement_shift: float = 3.0

## Camera rotation speed in deg/s
@export var camera_rotation_speed : float = 36.0 * 2.0


## Save initial camera view
@onready var camera_home: Transform3D = $Camera.transform


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
		handled = true

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
	elif event.is_action_pressed(&"reconnect"):
		$Receiver/JSONWebSocketReceiver.reconnect()
		handled = true

	if handled:
		get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	var camera_vector := Vector3.ZERO
#	var camera_transform := $Camera.transform as Transform3D
#	var camera_changed := false

	## TODO: handle shift
	## TODO: use input strength
	## TODO: use Node3D.translate()/rotate() or transform?

	## Movement along global axes
	if Input.is_action_pressed(&"move_forward"):
		camera_vector += Vector3.FORWARD

	if Input.is_action_pressed(&"move_back"):
		camera_vector += Vector3.BACK

	if Input.is_action_pressed(&"move_left"):
		camera_vector += Vector3.LEFT

	if Input.is_action_pressed(&"move_right"):
		camera_vector += Vector3.RIGHT

	if Input.is_action_pressed(&"move_up"):
		camera_vector += Vector3.UP

	if Input.is_action_pressed(&"move_down"):
		camera_vector += Vector3.DOWN

	if camera_vector.length():
		## adjust to camera rotation
		camera_vector = camera_vector.rotated(Vector3.UP, $Camera.rotation.y)
		#$Camera.translate(camera_vector * camera_movement_speed * delta)
		$Camera.transform = $Camera.transform.translated(camera_vector.normalized() * camera_movement_speed * delta)
		camera_vector = Vector3.ZERO


	## Movement along local axes
	if Input.is_action_pressed(&"zoom_in"):
		camera_vector += Vector3.FORWARD

	if Input.is_action_pressed(&"zoom_out"):
		camera_vector += Vector3.BACK

	if camera_vector.length():
		#$Camera.translate_object_local(camera_vector * camera_movement_speed * delta)
		$Camera.transform = $Camera.transform.translated_local(camera_vector.normalized() * camera_movement_speed * delta)
		camera_vector = Vector3.ZERO


	## Left/right rotates around global y axis
	if Input.is_action_pressed(&"look_left"):
		camera_vector += Vector3.UP

	if Input.is_action_pressed(&"look_right"):
		camera_vector += Vector3.DOWN

	if camera_vector.length():
		$Camera.rotate(camera_vector.normalized(), deg_to_rad(camera_rotation_speed * delta))
		camera_vector = Vector3.ZERO


	## Up/down rotates around local x axis
	if Input.is_action_pressed(&"look_up"):
		camera_vector += Vector3.LEFT

	if Input.is_action_pressed(&"look_down"):
		camera_vector += Vector3.RIGHT

	if camera_vector.length():
		$Camera.rotate_object_local(camera_vector.normalized(), deg_to_rad(camera_rotation_speed * delta))
		camera_vector = Vector3.ZERO

#	if camera_changed:
#		$Camera.transform = camera_transform


func _process(delta: float) -> void:
	if idle_spin:
		$Camera.rotate_y((int(delta * 1000.0) % (idle_spin_speed * 1000)) / (idle_spin_speed * 1000.0) * 2.0 * PI)
