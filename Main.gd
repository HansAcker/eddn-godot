extends Node3D


## TODO: explain why which input is handled where
## TODO: move camera movement/presets into its own script


## Camera presets
const camera_presets_default := {
	&"RobigoRun" : Transform3D(Vector3(0.8739, 0, -0.486092), Vector3(-0.107088, 0.975431, -0.192521), Vector3(0.474148, 0.220304, 0.852429), Vector3(338, 16, -309)),
	&"Colonia" : Transform3D(Vector3(0.952749, 0, -0.303735), Vector3(0.058642, 0.981182, 0.183953), Vector3(0.298019, -0.193074, 0.93482), Vector3(9547.755, -903.6143, 19846.2)),
	&"Shinra" : Transform3D(Vector3(-0.333609, 0, 0.942708), Vector3(0.193754, 0.97865, 0.068566), Vector3(-0.922581, 0.205529, -0.326487), Vector3(-91.55039, 24.33843, 0.598375)),
}


## Idly spin around the y axis. Press "pause" input to stop/start.
@export var idle_spin: bool = true

## Seconds per rotation.
## TODO: add configuration warning. must not be 0. negative values rotate clockwise.
@export var idle_spin_speed: int = 120

## Camera movement speed in ly/s
@export var camera_movement_speed : float = 400.0

## Camera movement speed factor when shift key pressed.
#@export var camera_movement_shift: float = 3.0

## Camera rotation speed in deg/s
@export var camera_rotation_speed : float = 36.0 * 3.0

## Pre-defined camera views.
@export var camera_presets : Array[Transform3D] = [camera_presets_default[&"RobigoRun"], camera_presets_default[&"Colonia"], camera_presets_default[&"Shinra"]]

## Seconds to reach preset view.
@export var camera_preset_speed: float = 1.0


## Save initial camera view
@onready var camera_home: Transform3D = ($Camera as Node3D).transform


var _camera_tween_ref: WeakRef = weakref(null)
func _move_camera(where: Transform3D, when: float) -> void:
		var camera := $Camera as Node3D
		if is_zero_approx(when):
			camera.transform = where
		else:
			var _tween = _camera_tween_ref.get_ref()
			if is_instance_valid(_tween) && is_instance_of(_tween, Tween):
				(_tween as Tween).kill()
			_camera_tween_ref = weakref(create_tween().tween_property(camera, "transform", where, when))

func _handle_preset(index: int, tween: bool = true, store: bool = false) -> void:
	if store:
		if len(camera_presets) <= index:
			camera_presets.resize(index+1)
		camera_presets[index] = $Camera.transform
		print("stored camera preset %d: %s" % [index, camera_presets[index]])
	elif len(camera_presets) > index && camera_presets[index] != Transform3D.IDENTITY:  ## IDENTITY is at Sol's center, looking south
		_move_camera(camera_presets[index], camera_preset_speed if tween else 0.0)
	else:
		print("no camera preset at index %d" % index)


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
#			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		handled = true
	elif event.is_action_pressed(&"pause"):
		idle_spin = !idle_spin
		handled = true
	elif event.is_action_pressed(&"edsm_fetch"):
		$Map/EDSMQuery.add_stars_at($Camera.position)
		handled = true

	if handled:
		get_viewport().set_input_as_handled()


func _unhandled_key_input(event: InputEvent) -> void:
	var handled := false

	## TODO: match something instead of ifs?

	if event.is_action_pressed(&"ui_home"):
		_move_camera(camera_home, 1.0 if !event.shift_pressed else 0.0)
		handled = true
	elif event.is_action_pressed(&"clear"):
		$Map/StarManager.clear()
		handled = true
	elif event.is_action_pressed(&"reconnect"):
		$Receiver/JSONWebSocketReceiver.reconnect()
		handled = true
	elif event.is_action_pressed(&"print_transform"):
		var camera_transform := $Camera.transform as Transform3D
		var camera_basis := camera_transform.basis
		var camera_origin := camera_transform.origin
		print("Transform3D(Vector3%s, Vector3%s, Vector3%s, Vector3%s)," % [camera_basis.x, camera_basis.y, camera_basis.z, camera_origin])
		handled = true
	elif event.is_action_pressed(&"preset_0"):
		_handle_preset(0, !event.shift_pressed, event.ctrl_pressed)
		handled = true
	elif event.is_action_pressed(&"preset_1"):
		_handle_preset(1, !event.shift_pressed, event.ctrl_pressed)
		handled = true
	elif event.is_action_pressed(&"preset_2"):
		_handle_preset(2, !event.shift_pressed, event.ctrl_pressed)
		handled = true
	elif event.is_action_pressed(&"preset_3"):
		_handle_preset(3, !event.shift_pressed, event.ctrl_pressed)
		handled = true

	if handled:
		get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	var camera_vector := Vector3.ZERO
	var camera := $Camera as Camera3D

#	var camera_transform := $Camera.transform as Transform3D
#	var camera_changed := false

	## TODO: handle shift for faster movement with keys
	## TODO: use Node3D.translate()/rotate() or transform?
	## TODO: reconcile normalizing vectors with input strength
	## TODO: implement "zoom": scale movement speed with zoom factor
	## TODO: use mouse wheel for zoom

	## Movement along global axes
	if Input.is_action_pressed(&"move_forward"):
		camera_vector += Vector3.FORWARD * Input.get_action_strength(&"move_forward")

	if Input.is_action_pressed(&"move_back"):
		camera_vector += Vector3.BACK * Input.get_action_strength(&"move_back")

	if Input.is_action_pressed(&"move_left"):
		camera_vector += Vector3.LEFT * Input.get_action_strength(&"move_left")

	if Input.is_action_pressed(&"move_right"):
		camera_vector += Vector3.RIGHT * Input.get_action_strength(&"move_right")

	if Input.is_action_pressed(&"move_up"):
		camera_vector += Vector3.UP * Input.get_action_strength(&"move_up")

	if Input.is_action_pressed(&"move_down"):
		camera_vector += Vector3.DOWN * Input.get_action_strength(&"move_down")

	if camera_vector.length():
		## adjust to camera rotation
		camera_vector = camera_vector.rotated(Vector3.UP, camera.rotation.y)
		camera.transform = camera.transform.translated(camera_vector * camera_movement_speed * delta)
		camera_vector = Vector3.ZERO


	## Movement along local axes
	if Input.is_action_pressed(&"zoom_in"):
		camera_vector += Vector3.FORWARD * Input.get_action_strength(&"zoom_in")

	if Input.is_action_pressed(&"zoom_out"):
		camera_vector += Vector3.BACK * Input.get_action_strength(&"zoom_out")

	if camera_vector.length():
		camera.transform = camera.transform.translated_local(camera_vector * camera_movement_speed * delta)
		camera_vector = Vector3.ZERO


	## Left/right rotates around global y axis
	if Input.is_action_pressed(&"look_left"):
		camera.rotate(Vector3.UP, deg_to_rad(camera_rotation_speed * Input.get_action_strength(&"look_left") * delta))

	if Input.is_action_pressed(&"look_right"):
		camera.rotate(Vector3.DOWN, deg_to_rad(camera_rotation_speed * Input.get_action_strength(&"look_right") * delta))


	## Up/down rotates around local x axis
	if Input.is_action_pressed(&"look_up"):
		camera.rotate_object_local(Vector3.LEFT, deg_to_rad(camera_rotation_speed * Input.get_action_strength(&"look_up") * delta))

	if Input.is_action_pressed(&"look_down"):
		camera.rotate_object_local(Vector3.RIGHT, deg_to_rad(camera_rotation_speed * Input.get_action_strength(&"look_down") * delta))


func _process(delta: float) -> void:
	if idle_spin:
		$Camera.rotate_y((int(delta * 1000.0) % (idle_spin_speed * 1000)) / (idle_spin_speed * 1000.0) * 2.0 * PI)
