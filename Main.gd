extends Node3D


## TODO: explain why which input is handled where
## TODO: move camera movement/presets into its own script


## Camera presets
const camera_presets_default := {
	&"Overview": Transform3D(Vector3(-0.939693, 0, -0.34202), Vector3(-0.196175, 0.819152, 0.538985), Vector3(0.280167, 0.573577, -0.769751), Vector3(4000, 4000, -4000)),
	&"RobigoRun": Transform3D(Vector3(0.8739, 0, -0.486092), Vector3(-0.107088, 0.975431, -0.192521), Vector3(0.474148, 0.220304, 0.852429), Vector3(338, 16, -309)),
	&"Colonia": Transform3D(Vector3(0.952749, 0, -0.303735), Vector3(0.058642, 0.981182, 0.183953), Vector3(0.298019, -0.193074, 0.93482), Vector3(9547.755, -903.6143, 19846.2)),
	&"Shinra": Transform3D(Vector3(-0.333609, 0, 0.942708), Vector3(0.193754, 0.97865, 0.068566), Vector3(-0.922581, 0.205529, -0.326487), Vector3(-91.55039, 24.33843, 0.598375)),
}


## Idly spin around the y axis. Press "pause" input to stop/start.
@export var idle_spin: bool = true

## Seconds per rotation.
## TODO: add configuration warning. must not be 0. negative values rotate clockwise.
@export var idle_spin_speed: int = 120

## Idly move the camera around. Press "pause2" input to stop/start
@export var idle_move: bool = true

## Camera movement speed in ly/s
@export var camera_movement_speed: float = 400.0

## Camera movement speed factor when shift key pressed.
#@export var camera_movement_shift: float = 3.0

## Camera rotation speed in deg/s
@export var camera_rotation_speed: float = 36.0 * 3.0

## Pre-defined camera views.
@export var camera_presets: Array[Transform3D] = [
	camera_presets_default[&"Overview"],
	camera_presets_default[&"RobigoRun"],
	camera_presets_default[&"Shinra"],
	camera_presets_default[&"Colonia"],
]

## Seconds to reach preset view.
@export var camera_preset_speed : float = 3.0


@onready var camera := $Camera as Node3D

## Save initial camera view
@onready var camera_home : Transform3D = camera.transform

@onready var idle_timer : Timer = $IdleTimer

## Keep a weak reference only, so finished Tweens can be freed
var _camera_tween_ref: WeakRef = weakref(null)

## Fixed-seed seudorandomness for idle move positions, so EDSM requests can be cached
var _camera_randomizer := RandomNumberGenerator.new()


func _ready() -> void:
	_camera_randomizer.seed = 423.591


func _move_camera(where: Transform3D, when: float) -> void:
		if is_zero_approx(when):
			camera.transform = where
		else:
			var _tween = _camera_tween_ref.get_ref()
			if is_instance_valid(_tween) && is_instance_of(_tween, Tween):
				(_tween as Tween).kill()

			var tween := create_tween()
			tween.tween_property(camera, "transform", where, when).set_trans(Tween.TRANS_QUINT)
			_camera_tween_ref = weakref(tween)


func _handle_preset(index: int, tween: bool = true, store: bool = false) -> bool:
	if store:
		if len(camera_presets) <= index:
			camera_presets.resize(index+1)
		camera_presets[index] = camera.transform
		print("stored camera preset %d: %s" % [index, camera_presets[index]])
		return true

	if len(camera_presets) > index && (camera_presets[index] as Transform3D) != Transform3D.IDENTITY:  ## IDENTITY is at Sol's center, looking south
		_move_camera(camera_presets[index], camera_preset_speed if tween else 0.0)
		print("moving to preset %d %s" % [index, camera_presets[index]])
		return true

	print("no camera preset at index %d" % index)
	return false


func _unhandled_input(event: InputEvent) -> void:
	var handled := false

	## toggle fullscreen	
	## TODO: often hangs and crashes. also on resizing or moving the window. why?
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
	elif event.is_action_pressed(&"pause2"):
		idle_move = !idle_move
#		if idle_move:
#			idle_timer.start()
#		else:
#			idle_timer.stop()
		handled = true
	elif event.is_action_pressed(&"edsm_fetch"):
		$Map/EDSMQuery.add_stars_at(camera.position)
		handled = true
	elif event.is_action_pressed(&"random_move"):
		_on_idle_timer_timeout()
		handled = true

	if handled:
		get_viewport().set_input_as_handled()
		idle_timer.start()


func _unhandled_key_input(event: InputEvent) -> void:
	var handled := false

	## TODO: match something instead of ifs?
	##       or ["&preset_0", &"preset_1"]...find(action)?

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
		var camera_transform := camera.transform
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
	elif event.is_action_pressed(&"preset_4"):
		_handle_preset(4, !event.shift_pressed, event.ctrl_pressed)
		handled = true
	elif event.is_action_pressed(&"preset_5"):
		_handle_preset(5, !event.shift_pressed, event.ctrl_pressed)
		handled = true
	elif event.is_action_pressed(&"preset_6"):
		_handle_preset(6, !event.shift_pressed, event.ctrl_pressed)
		handled = true

	if handled:
		get_viewport().set_input_as_handled()
		idle_timer.start()


func _physics_process(delta: float) -> void:
	var handled := false
	var camera_vector := Vector3.ZERO
	var input_vector : Vector2

#	var camera_transform := $Camera.transform as Transform3D
#	var camera_changed := false

	## TODO: handle shift for faster movement with keys
	## TODO: use Node3D.translate()/rotate() or transform?
	## TODO: reconcile normalizing vectors with input strength
	## TODO: implement "zoom": scale movement speed with zoom factor
	## TODO: use mouse wheel for zoom


	## Camera movement: Input strength included in get_axis() value

	## Movement along global axes
	input_vector = Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")
	camera_vector = Vector3(input_vector.x, Input.get_axis(&"move_down", &"move_up"), input_vector.y)

	if camera_vector.length():
		## adjust to camera rotation
		camera_vector = camera_vector.rotated(Vector3.UP, camera.rotation.y)
		camera.transform = camera.transform.translated(camera_vector * camera_movement_speed * delta)
		camera_vector = Vector3.ZERO
		handled = true


	## Movement along local axes
	camera_vector = Vector3.FORWARD * Input.get_axis(&"move_back2", &"move_forward2")

	if camera_vector.length():
		camera.transform = camera.transform.translated_local(camera_vector * camera_movement_speed * delta)
		camera_vector = Vector3.ZERO
		handled = true


	input_vector = Input.get_vector(&"look_right", &"look_left", &"look_down", &"look_up")

	if input_vector.length():
		## Left/right rotates around global y axis
		camera.rotate(Vector3.UP, deg_to_rad(input_vector.x * camera_rotation_speed * delta))
		## Up/down rotates around local x axis
		camera.rotate_object_local(Vector3.LEFT, deg_to_rad(input_vector.y * camera_rotation_speed * delta))
		handled = true

	if handled:
		idle_timer.start()


func _process(delta: float) -> void:
	if idle_spin:
		camera.rotate_y((int(delta * 1000.0) % (idle_spin_speed * 1000)) / (idle_spin_speed * 1000.0) * 2.0 * PI)


func _on_idle_timer_timeout() -> void:
	if !idle_move:
		return

	var _tween = _camera_tween_ref.get_ref()
	if is_instance_valid(_tween) && is_instance_of(_tween, Tween):
		(_tween as Tween).kill()

#	_camera_randomizer.randomize()
	var choice := _camera_randomizer.randf()
	var move_to_pos := Vector3(_camera_randomizer.randf_range(-134.2, 134.2), _camera_randomizer.randf_range(-20.4, 234.2), _camera_randomizer.randf_range(-423.5, 234.2))

	var look_at_pos := Vector3(randf_range(-52.2, 34.2), -10.0, randf_range(-23.5, 423.5))
	var preset := randi_range(0, len(camera_presets)-1)

	var camera_transform := camera.transform
	if choice >= 0.85 && len(camera_presets) && _handle_preset(preset):
		idle_spin = false
	else:
		print("move to: ", move_to_pos, ", look at: ", look_at_pos)

		camera_transform.origin = move_to_pos
		camera_transform = camera_transform.looking_at(look_at_pos)

		## TODO: make transition configurable
		var tween := create_tween()
		tween.tween_property(camera, "transform", camera_transform, 6.0).set_trans(Tween.TRANS_QUINT)
		_camera_tween_ref = weakref(tween)

		## Populate space around the camera from EDSM
		$Map/EDSMQuery.add_stars_at(camera_transform.origin)

		idle_spin_speed = -idle_spin_speed
		idle_spin = true
