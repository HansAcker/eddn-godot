class_name StarManager
extends Node


## adds and removes star sprites
## TODO: freeze stars into something more easier on the engine. ArrayMesh?
##       keep individually animated sprites only while the effect runs.
## TODO: event nodes use get_node("../../....") to get here. use something else.


## Increase star size by this factor on activity.
@export var flare_size : float = 10.0

## Increase star size by this factor on first activity.
@export var flare_size_new : float = 20.0

## Increase star size with distance to camera.
@export var distance_factor : float = 1000.0

## Time to full flare size in seconds.
@export var flare_up : float = 0.1

## Time to normal size in seconds.
@export var flare_down : float = 0.2


## TODO: UI quick hack. Think again.
signal counter(count : int)


class _StarEntry:
	var system: StarSystemRecord  ## system name, class and location
	var star: SpriteBase3D  ## the star node
	var label: Label3D  ## the star's label
	var expire_tick: int  ## msec tick after which the star should be deleted
	var tween_ref: WeakRef  ## not to keep finished Tweens around
	var alpha: float  ## additional alpha applied to color
	var color: Color  ## original color, for tweening
	var pixel_size: float  ## original size, for tweening

var _stars := {}
var _delete_queue: Array[Node3D] = []
var _expire_ticks := {}


func add(star_system: StarSystemRecord, expire_msec: int = 0, alpha: float = 1.0, highlight: bool = true) -> void:
	## get_ticks_msec() wraps after roughly 500 million years. don't run that long.
	var expire_tick : int = Time.get_ticks_msec() + expire_msec if expire_msec > 0 else 0

	var id := star_system.id
	if id == -1 || star_system.position == StarSystemRecord.POS_INVALID:
		print("StarManager refusing to add invalid system: ", star_system)
		return

	## Scale highlight effects with distance to camera
	## TODO: maybe exponential scale?
	var dist_scale := maxf(1.0, get_viewport().get_camera_3d().position.distance_to(star_system.position) / distance_factor)

	if (star_system.id in _stars):
		var star_entry := _stars[id] as _StarEntry
		var system_entry := star_entry.system
		var star := star_entry.star

		## TODO: also update .system?

		## update alpha if larger
		if (alpha > star_entry.alpha):
			star_entry.alpha = alpha

		## highlight activity only if no Tween already running
		if highlight:
			var _tween = star_entry.tween_ref.get_ref()
			if !(is_instance_valid(_tween) && _tween is Tween && (_tween as Tween).is_running()):
					var tween := create_tween().set_parallel()
					tween.tween_property(star, "pixel_size", star_entry.pixel_size * flare_size * dist_scale, flare_up)
					tween.tween_property(star, "modulate", star_entry.color * alpha, flare_up).set_trans(Tween.TRANS_EXPO)  ## use event alpha here, could be smaller than before
					tween.chain()
					tween.tween_property(star, "pixel_size", star_entry.pixel_size, flare_down).set_trans(Tween.TRANS_EXPO)
					tween.tween_property(star, "modulate", star_entry.color * star_entry.alpha, flare_up)  ## return to saved alpha
					star_entry.tween_ref = weakref(tween)

		## update timeout
		## TODO: could expire() delete the entry while in here?
		if expire_tick > star_entry.expire_tick:
			star_entry.expire_tick = expire_tick
			_expire_ticks[id] = expire_tick

		if system_entry.name.is_empty() && !star_system.name.is_empty():
			system_entry.name = star_system.name
			print("Found name for %d: %s" % [system_entry.id, system_entry.name])

		var _label := star_entry.label
		if _label is Label3D:
			(_label as Label3D).text = "%s\n%s" % [system_entry.name, star_system.event_type]

		## TODO: "Scan" events in multi-star systems change classes. Select main star.
		## TODO: use .is_empty() on StringName or == &""?
		#if star_system.star_class != &"" && star_system.star_class != system_entry.star_class:
		if system_entry.star_class.is_empty() && !star_system.star_class.is_empty():
#			print("Star class changed: %s %s -> %s" % [star_system.name, system_entry.star_class, star_system.star_class])
			## TODO: could just change color. but maybe also use different sprites.
			delete_id(id, false)
		else:
			## TODO: better code-path
			return

	## set sprite from star class or default
	var Star := StarClasses.sprites[&"default"]
	if star_system.star_class in StarClasses.sprites:
		Star = StarClasses.sprites[star_system.star_class]

	var star := Star.instantiate() as SpriteBase3D
	star.transform.origin = star_system.position

	## set color from star class or default
	var color := StarClasses.colors[&"default"]
	if star_system.star_class in StarClasses.colors:
		color = StarClasses.colors[star_system.star_class]
	elif !star_system.star_class.is_empty():
		print("not in colors: %s" % star_system.star_class)
	star.modulate = color * alpha

	var star_entry := _StarEntry.new()
	star_entry.system = star_system
	star_entry.star = star
	star_entry.expire_tick = expire_tick
	star_entry.color = color
	star_entry.alpha = alpha
	star_entry.pixel_size = star.pixel_size

	if expire_tick:
		_expire_ticks[id] = expire_tick

	var tween = create_tween()
	star_entry.tween_ref = weakref(tween)

	if highlight:
		## TODO: could it glow more with color values > 1.0?
		tween.tween_property(star, "pixel_size", star.pixel_size * flare_size_new * dist_scale, flare_up)
		tween.tween_property(star, "pixel_size", star.pixel_size, flare_down)
	else:
		star.modulate = Color(0.0, 0.0, 0.0, 0.0)
		tween.tween_property(star, "modulate", color * alpha, flare_up + flare_down)

	var _label := star.get_node_or_null("Label")
	if _label is Label3D:
		var label := _label as Label3D
		star_entry.label = label
		label.text = "%s\n%s" % [star_system.name, star_system.event_type]
		create_tween().tween_property(label, "modulate", label.modulate, flare_up + flare_down)
		label.modulate = Color(0.0, 0.0, 0.0, 0.0)

	_stars[star_system.id] = star_entry;

	add_child(star)
	counter.emit(len(_stars))


func delete_id(id: int, fade: bool = true) -> void:
	if id in _stars:
		if _stars[id] is _StarEntry:  ## TODO: only checked here. how would an entry not be of StarEntry type?
			var star_entry := _stars[id] as _StarEntry
			var _tween = star_entry.tween_ref.get_ref()
			if is_instance_valid(_tween) && _tween is Tween:
				(_tween as Tween).kill()  ## stop animation

			var remove_func := (func(star: Node3D) -> void:
				remove_child(star)
				_delete_queue.push_back(star)
			).bind(star_entry.star)

			if fade:
				var tween := create_tween().set_parallel()
				tween.finished.connect(remove_func)
				tween.tween_property(star_entry.star, "modulate", Color(0.0, 0.0, 0.0, 0.0), flare_up + flare_down)
				if is_instance_valid(star_entry.label) && star_entry.label is Label3D:
					tween.tween_property(star_entry.label, "modulate", Color(0.0, 0.0, 0.0, 0.0), flare_up + flare_down)
			else:
				remove_func.call()
		_stars.erase(id)
#		counter.emit(len(_stars))


func clear() -> void:
	var count : int = 0
	for star_key in _stars.keys():
		delete_id(star_key)
		count += 1
		if count >= 1000:
			await get_tree().process_frame  ## TODO: or physics_frame? when does queue_free() free the node?
			count = 0
	counter.emit(len(_stars))


#func expire() -> int:
#	var now := Time.get_ticks_msec()
#	var count : int = 0
#
#	## TODO: something more efficient than iterating over thousands of objects
#	for star_key in _stars.keys():
#		var star_entry := _stars[star_key] as _StarEntry
#		if star_entry.expire_tick > 0 && now >= star_entry.expire_tick:
#			count += 1
#			delete_id(star_key)
#
#	counter.emit(len(_stars))
#	return count

func expire() -> int:
	var now := Time.get_ticks_msec()
	var count : int = 0
	var i : int = 0

	## TODO: this probably isn't much better, anyway
	for id in _expire_ticks.keys():
		var expire_tick := _expire_ticks[id] as int
		if now >= expire_tick:
			count += 1
			delete_id(id)
			_expire_ticks.erase(id)

	counter.emit(len(_stars))
	return count


func _on_expire_timer_timeout() -> void:
	var ts := Time.get_ticks_usec()
	var count := expire()
	print("StarManager expire took %dµs, removed %d nodes" % [(Time.get_ticks_usec() - ts), count])


func _on_delete_timer_timeout() -> void:
	if !len(_delete_queue):
		return

	## TODO: allow parallel runs or not? does it even work?
	$DeleteTimer.stop()

	var ts := Time.get_ticks_usec()
	var count: int = 0
	var i: int = 0

	var queue := _delete_queue
	_delete_queue = []

	$DeleteTimer.start()

	for star in queue:
		if is_instance_valid(star):
#			star.queue_free()
			star.free()
			count += 1
			i += 1
			if i >= 100:  ## TODO: arbitrary value. think again.
				await get_tree().process_frame
				i = 0

	print("StarManager delete queue took %dµs, deleted %d nodes" % [(Time.get_ticks_usec() - ts), count])
