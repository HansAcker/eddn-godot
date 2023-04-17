class_name StarManager
extends Node


## adds and removes star sprites
## TODO: freeze stars into something more easier on the engine. ArrayMesh?
##       keep individually animated sprites only while the effect runs.
## TODO: event nodes use get_node("../../....") to get here. use something else.


## Increase star size by this factor on activity.
@export var flare_size: float = 10.0

## Increase star size by this factor on first activity.
@export var flare_size_new : float = 20.0

## Increase star size with distance to camera.
@export var distance_factor : float = 1000.0

## Time to full flare size in seconds.
@export var flare_up: float = 0.1

## Time to normal size in seconds.
@export var flare_down: float = 0.2


## TODO: UI quick hack. Think again.
signal counter(count: int)


class _StarEntry:
	var system: StarSystemRecord  ## system name, class and location
	var star: SpriteBase3D  ## the star node
	var expire_tick: int  ## msec tick after which the star should be deleted
	var tween_ref: WeakRef  ## not to keep finished Tweens around
	var alpha: float  ## additional alpha applied to color
	var color: Color  ## original color, for tweening
	var pixel_size: float  ## original size, for tweening

var _stars := {}


func add(star_system: StarSystemRecord, expire_msec: int = 0, alpha: float = 1.0) -> void:
	## get_ticks_msec() wraps after roughly 500 million years. don't run that long.
	var expire_tick : int = Time.get_ticks_msec() + expire_msec if expire_msec > 0 else 0
	var id := star_system.id

	if id == -1 || star_system.position == StarSystemRecord.POS_INVALID:
		print("StarManager refusing to add invalid system: ", star_system)
		return

	## Scale highlight effects with distance to camera
	var dist_scale := maxf(1.0, get_viewport().get_camera_3d().position.distance_to(star_system.position) / distance_factor)

	if (star_system.id in _stars):
		var star_entry := _stars[id] as _StarEntry
		var system_entry := star_entry.system
		var star := star_entry.star

		## TODO: also update .system?

		var _tween = star_entry.tween_ref.get_ref()
		if !(is_instance_valid(_tween) && is_instance_of(_tween, Tween) && (_tween as Tween).is_running()):
			## highlight activity
			var tween := create_tween().set_parallel()
			tween.tween_property(star, "pixel_size", star_entry.pixel_size * flare_size * dist_scale, flare_up)
			## update alpha if larger
			if (alpha > star_entry.alpha):
				star_entry.alpha = alpha
				tween.tween_property(star, "modulate", star_entry.color * alpha, flare_up)
			tween.chain()
			tween.tween_property(star, "pixel_size", star_entry.pixel_size, flare_down).set_trans(Tween.TRANS_EXPO)
			star_entry.tween_ref = weakref(tween)

		## update timeout
		## TODO: could expire() delete the entry while in here?
		if expire_tick > star_entry.expire_tick:
			star_entry.expire_tick = expire_tick

		if system_entry.name.is_empty() && !star_system.name.is_empty():
			system_entry.name = star_system.name
			print("Found name for %d: %s" % [system_entry.id, system_entry.name])

		## TODO: "Scan" events in multi-star systems change classes. Select main star.
		## TODO: use .is_empty() on StringName or == &""?
		#if star_system.star_class != &"" && star_system.star_class != system_entry.star_class:
		if system_entry.star_class.is_empty() && !star_system.star_class.is_empty():
#			print("Star class changed: %s %s -> %s" % [star_system.name, system_entry.star_class, star_system.star_class])
			## TODO: could just change color. but maybe also use different sprites.
			delete_id(id)
		else:
			## TODO: better code-path
			return

	## set sprite from star class or default
	var Star := StarClasses.sprites[&"default"]
	if star_system.star_class in StarClasses.sprites:
		Star = StarClasses.sprites[star_system.star_class]

	var star := Star.instantiate() as SpriteBase3D
	star.transform.origin = star_system.position

	var _label := star.get_node_or_null("Label")
	if _label is Label3D:
		(_label as Label3D).text = star_system.name

	## set color from star class or default
	var color := StarClasses.colors[&"default"]
	if star_system.star_class in StarClasses.colors:
		color = StarClasses.colors[star_system.star_class]
	elif !star_system.star_class.is_empty():
		print("not in colors: %s" % star_system.star_class)
	star.modulate = color * alpha

	var tween = create_tween()
	## TODO: make effect configurable
	## TODO: could it glow more with color values > 1.0?
	tween.tween_property(star, "pixel_size", star.pixel_size * flare_size_new * dist_scale, flare_up)
	tween.tween_property(star, "pixel_size", star.pixel_size, flare_down)

	var star_entry := _StarEntry.new()
	star_entry.system = star_system
	star_entry.star = star
	star_entry.expire_tick = expire_tick
	star_entry.tween_ref = weakref(tween)
	star_entry.color = color
	star_entry.alpha = alpha
	star_entry.pixel_size = star.pixel_size

	_stars[star_system.id] = star_entry;

	add_child(star)
	counter.emit(len(_stars))


func delete_id(id: int) -> void:
	if id in _stars:
		if _stars[id] is _StarEntry:  ## TODO: only checked here. how would an entry not be of StarEntry type?
			var star_entry := _stars[id] as _StarEntry
			var _tween = star_entry.tween_ref.get_ref()
			if is_instance_valid(_tween) && is_instance_of(_tween, Tween):
				_tween.kill()  ## stop animation
			star_entry.star.queue_free()  ## remove star from scene
		_stars.erase(id)
#		counter.emit(len(_stars))


## TODO: use co-routine, don't block the loop
func clear() -> void:
	for star_key in _stars.keys():
		delete_id(star_key)
	counter.emit(len(_stars))


func expire() -> int:
	var now := Time.get_ticks_msec()
	var count : int = 0

	## TODO: something more efficient than iterating over thousands of objects
	for star_key in _stars.keys():
		var star_entry := _stars[star_key] as _StarEntry
		if star_entry.expire_tick > 0 && now > star_entry.expire_tick:
#			print("Expired Key: ", star_key, " Entry: ", star_entry)
			count += 1
			delete_id(star_key)

	counter.emit(len(_stars))
	return count

func _on_expire_timer_timeout() -> void:
	var ts := Time.get_ticks_usec()
	var count := expire()
#	print("StarManager.expire() took %dµs, removed %d nodes" % [(Time.get_ticks_usec() - ts), count])
