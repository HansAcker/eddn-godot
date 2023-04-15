class_name StarManager
extends Node


## adds and removes star sprites
## TODO: PointMeshes?
## TODO: event nodes use get_node("../../....") to get here. use something else.


## TODO: UI quick hack. Think again.
signal counter(count: int)

class StarEntry:
	var system: StarSystemRecord  ## system name, class and location
	var star: SpriteBase3D  ## the star node
	var expire_tick: int  ## msec tick after which the star should be deleted
	var tween: Tween
	var alpha: float
	var pixel_size: float

var _stars := {}


func add(star_system: StarSystemRecord, expire_msec: int = 0, alpha: float = 1.0) -> void:
	## get_ticks_msec() wraps after roughly 500 million years. don't run that long.
	var expire_tick : int = Time.get_ticks_msec() + expire_msec if expire_msec > 0 else 0
	var id := star_system.id

	if id == -1 || star_system.position == StarSystemRecord.POS_INVALID:
		print("StarManager refusing to add invalid system: ", star_system)
		return

	if (star_system.id in _stars):
		var star_entry := _stars[id] as StarEntry
		var system_entry := star_entry.system as StarSystemRecord

		## TODO: also update .system?
		## TODO: update alpha

		var tween := star_entry.tween
		var star := star_entry.star

		if !tween.is_running():
			## highlight activity
			tween = create_tween()
			tween.tween_property(star, "pixel_size", star_entry.pixel_size * 10.0, 0.1)
			tween.tween_property(star, "pixel_size", star_entry.pixel_size, 0.2).set_trans(Tween.TRANS_EXPO)
			star_entry.tween = tween

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

	var Star := StarClasses.sprites[&"default"]
	if star_system.star_class in StarClasses.sprites:
		Star = StarClasses.sprites[star_system.star_class]

	var star := Star.instantiate() as SpriteBase3D
	star.transform.origin = star_system.position

	var color := StarClasses.colors[&"default"]
	if star_system.star_class in StarClasses.colors:
		color = StarClasses.colors[star_system.star_class]
	elif star_system.star_class != &"":
		print("not in colors: %s" % star_system.star_class)
	star.modulate = color * alpha

	var tween = create_tween()
	## TODO: make effect configurable
	## TODO: maybe scale by distance to camera
	## TODO: could it glow more with color values > 1.0?
	tween.tween_property(star, "pixel_size", star.pixel_size * 20.0, 0.1)
	tween.tween_property(star, "pixel_size", star.pixel_size, 0.2)

	var star_entry := StarEntry.new()
	star_entry.system = star_system
	star_entry.star = star
	star_entry.expire_tick = expire_tick
	star_entry.tween = tween
	star_entry.alpha = alpha
	star_entry.pixel_size = star.pixel_size

	_stars[star_system.id] = star_entry;

	add_child(star)
	counter.emit(len(_stars))


func delete_id(id: int) -> void:
	if id in _stars:
		if _stars[id] is StarEntry:  ## TODO: only checked here. how would an entry not be of StarEntry type?
			var star_entry := _stars[id] as StarEntry
			star_entry.tween.kill()  ## stop animation
			star_entry.star.queue_free()  ## remove star from scene
		_stars.erase(id)
#		counter.emit(len(_stars))


func clear() -> void:
	for star_key in _stars.keys():
		delete_id(star_key)
	counter.emit(len(_stars))


func expire() -> int:
	var now := Time.get_ticks_msec()
	var count : int = 0

	## TODO: something more efficient than iterating over thousands of objects
	for star_key in _stars.keys():
		var star_entry := _stars[star_key] as StarEntry
		if star_entry.expire_tick > 0 && now > star_entry.expire_tick:
#			print("Expired Key: ", star_key, " Entry: ", star_entry)
			count = count+1
			delete_id(star_key)

	counter.emit(len(_stars))
	return count

func _on_expire_timer_timeout():
	var ts := Time.get_ticks_usec()
	var count := expire()
	print("StarManager.expire() took %dµs, removed %d nodes" % [(Time.get_ticks_usec() - ts), count])
