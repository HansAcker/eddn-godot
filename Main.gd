extends Node3D


## TODO: explain why which input is handled where
## TODO: move camera movement/presets into its own script


## Camera presets
const camera_presets_default := {
	&"Overview": Transform3D(Vector3(-0.939693, 0, -0.34202), Vector3(-0.196175, 0.819152, 0.538985), Vector3(0.280167, 0.573577, -0.769751), Vector3(4000, 4000, -4000)),
	&"RobigoRun": Transform3D(Vector3(0.8739, 0, -0.486092), Vector3(-0.107088, 0.975431, -0.192521), Vector3(0.474148, 0.220304, 0.852429), Vector3(338, 16, -309)),
	&"Colonia": Transform3D(Vector3(0.952749, 0, -0.303735), Vector3(0.058642, 0.981182, 0.183953), Vector3(0.298019, -0.193074, 0.93482), Vector3(9547.755, -903.6143, 19846.2)),
	&"Shinra": Transform3D(Vector3(-0.333609, 0, 0.942708), Vector3(0.193754, 0.97865, 0.068566), Vector3(-0.922581, 0.205529, -0.326487), Vector3(-91.55039, 24.33843, 0.598375)),
	&"Sol": Transform3D(Vector3(0.467023, 0, -0.884234), Vector3(0.317198, 0.933437, 0.167534), Vector3(0.825379, -0.358726, 0.435939), Vector3(22.57196, -9.927534, 12.79236)),
#	&"SomewhereElse": Transform3D(Vector3(-0.981324, 0, 0.192309), Vector3(0.00678, 0.99937, 0.034595), Vector3(-0.192189, 0.035254, -0.980704), Vector3(371.3056, -30.30889, -785.4951)),
}


@export_group("Camera", "camera_")

## Camera movement speed in ly/s
@export var camera_movement_speed: float = 300.0

## Camera movement speed factor when shift key pressed.
#@export var camera_movement_shift: float = 3.0

## Camera rotation speed in deg/s
@export var camera_rotation_speed: float = 36.0 * 2.0

## Seconds to reach preset view.
@export var camera_preset_speed: float = 4.0

## Pre-defined camera views.
@export var camera_presets: Array[Transform3D] = [
	camera_presets_default[&"Overview"],
	camera_presets_default[&"RobigoRun"],
	camera_presets_default[&"Shinra"],
	camera_presets_default[&"Colonia"],
	camera_presets_default[&"Sol"],
]

## Idly move the camera around. Press "pause" input to stop/start
@export var idle_move: bool = false

## Random seed for idle move positions. Useful if fetching EDSM data from a cache.
## Set to 0 for randomness.
@export var idle_move_seed: int = 42**23

## Show 2D overlay
@export var hide_ui: bool = false


## Keep a weak reference only, so finished Tweens can be freed
var _camera_tween_ref: WeakRef = weakref(null)

var _camera_randomizer := RandomNumberGenerator.new()


## Save references
## TODO: explain why this is supposedly better than using $Node everywhere?
## TODO: prefix with _ or not?
@onready var camera := $Camera as Node3D
@onready var edsm_handler := $Map/EDSMQuery  ## TODO: set class_name?
@onready var star_manager := $Map/StarManager as StarManager
@onready var idle_timer := $IdleTimer as Timer
@onready var ws_receiver := $Receiver/JSONWebSocketReceiver  ## TODO: set class_name?

## Save initial camera view
@onready var camera_home: Transform3D = camera.transform


func _ready() -> void:
#	randomize()
	if idle_move_seed:
		_camera_randomizer.seed = idle_move_seed


func _unhandled_input(event: InputEvent) -> void:
	var handled := false

	## toggle fullscreen	
	## TODO: often hangs and crashes. also on resizing or moving the window. why?
	if event.is_action_pressed(&"toggle_fullscreen"):
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
		idle_move = !idle_move
		if idle_move:
			_random_camera_move()
		handled = true
	elif event.is_action_pressed(&"edsm_fetch"):
		edsm_handler.add_stars_at(camera.position)
		handled = true
	elif event.is_action_pressed(&"random_move"):
		_random_camera_move()
		handled = true

	if handled:
		get_viewport().set_input_as_handled()
		idle_timer.start()


func _unhandled_key_input(_event: InputEvent) -> void:
	var event := _event as InputEventWithModifiers
	var handled := false

	## TODO: match something instead of ifs?
	##       or ["&preset_0", &"preset_1"]...find(action)?

	if event.is_action_pressed(&"ui_home"):
		_move_camera(camera_home, 1.0 if !event.shift_pressed else 0.0)
		handled = true
	elif event.is_action_pressed(&"clear"):
		star_manager.clear()
		handled = true
	elif event.is_action_pressed(&"reconnect"):
		ws_receiver.reconnect()
		handled = true
	elif event.is_action_pressed(&"print_transform"):
		var camera_transform := camera.transform
		var camera_basis := camera_transform.basis
		var camera_origin := camera_transform.origin
		print("Transform3D(Vector3%s, Vector3%s, Vector3%s, Vector3%s)," % [camera_basis.x, camera_basis.y, camera_basis.z, camera_origin])
		handled = true
	elif event.is_action_pressed(&"hide_ui"):
		hide_ui = !hide_ui
		if hide_ui:
			$UI.hide()
		else:
			$UI.show()
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
	var input_vector: Vector2
	var change_vector := Vector3.ZERO

	## TODO: handle shift for faster movement with keys
	## TODO: use Node3D.translate()/rotate() or transform?
	## TODO: implement "zoom": scale movement speed with zoom factor
	## TODO: use mouse wheel for zoom
	## TODO: better use approx_zero instead of change_vector.length? it works, though
	## TODO: orbit camera with focus point, pivot and dolly

	## Movement along global axes
	input_vector = Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")
	change_vector = Vector3(input_vector.x, Input.get_axis(&"move_down", &"move_up"), input_vector.y)

	if change_vector.length():
		## adjust to camera rotation
		change_vector = change_vector.rotated(Vector3.UP, camera.rotation.y)
		camera.transform = camera.transform.translated(change_vector * camera_movement_speed * delta)
		change_vector = Vector3.ZERO
		handled = true

	## Movement along local axes
	change_vector = Vector3.FORWARD * Input.get_axis(&"move_back2", &"move_forward2")

	if change_vector.length():
		camera.transform = camera.transform.translated_local(change_vector * camera_movement_speed * delta)
		change_vector = Vector3.ZERO
		handled = true

	input_vector = Input.get_vector(&"look_right", &"look_left", &"look_down", &"look_up")

	if input_vector.length():
		## Left/right rotates around global y axis
		camera.rotate(Vector3.UP, deg_to_rad(input_vector.x * camera_rotation_speed * delta))
		## Up/down rotates around local x axis
		camera.rotate_object_local(Vector3.LEFT, deg_to_rad(input_vector.y * camera_rotation_speed * delta))
		handled = true

	if handled:
		_stop_camera_tween()
		idle_timer.start()


func _stop_camera_tween() -> void:
	var _tween = _camera_tween_ref.get_ref()
	if is_instance_valid(_tween) && _tween is Tween:
		(_tween as Tween).kill()


func _move_camera(where: Transform3D, when: float) -> void:
	_stop_camera_tween()
	if is_zero_approx(when):
		camera.transform = where
	else:
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
#		$UI/Log.print("moving to preset %d %s" % [index, camera_presets[index]])
		return true

	print("no camera preset at index %d" % index)
	return false


func _random_camera_move() -> void:
	var choice := randf()

	## TODO: make preset probability configurable
	if choice >= 0.55 && len(camera_presets) && _handle_preset(randi_range(0, len(camera_presets)-1)):
		pass
	else:
		## use _camera_randomizer for position, default for orientation
		## TODO: make bounding box and focus points configurable
		## TODO: ensure "the direction from the node's position to the target vector cannot be parallel to the up vector"?
		var move_to_pos := Vector3(_camera_randomizer.randf_range(-134.2, 134.2), _camera_randomizer.randf_range(-20.4, 234.2), _camera_randomizer.randf_range(-423.5, 334.2))
		var look_at_pos := Vector3(randf_range(-34.2, 52.2), -10.0, randf_range(-23.5, 42.5))
		print("move to: %s, look at: %s" % [move_to_pos, look_at_pos])
#		$UI/Log.print("move to: %s, look at: %s" % [move_to_pos, look_at_pos])

		## Populate space around the camera from EDSM
		edsm_handler.add_stars_at(move_to_pos)

		var camera_transform := Transform3D(Basis(), move_to_pos).looking_at(look_at_pos)

		## Pan around on arrival
		var final_transform := Transform3D(camera_transform.basis, Vector3.ZERO).rotated(Vector3.UP, PI * (1.0 if randf() >= 0.5 else -1.0)).translated(camera_transform.origin)

		## TODO: make transition configurable
		_stop_camera_tween()
		var tween := create_tween()
		tween.tween_property(camera, "transform", camera_transform, 8.0).set_trans(Tween.TRANS_QUINT)
		tween.tween_property(camera, "transform", final_transform, 90.0)
		_camera_tween_ref = weakref(tween)

		## TODO: camera FoV effects?
#		var xtween := create_tween()
#		xtween.tween_property(camera, "fov", 90.0, 1.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
#		xtween.tween_property(camera, "fov", 65.0, 3.0).set_ease(Tween.EASE_OUT)


func _on_idle_timer_timeout() -> void:
	if !idle_move:
		return

	_random_camera_move()
