class_name StarManager
extends Node


## adds and removes star sprites
## TODO: PointMeshes?

## TODO: UI quick hack. Think again.
signal counter(count: int)


var _stars := {}


## TODO: alpha parameter?
func add(star_system: StarSystemRecord, expire_msec: int = 0) -> void:
	## get_ticks_msec() wraps after roughly 500 million years. don't run that long.
	var expire_tick : int = Time.get_ticks_msec() + expire_msec if expire_msec > 0 else 0
	var id := star_system.id

	if id == -1:
		print("StarManager refusing to add system -1: ", star_system)
		return

	if (star_system.id in _stars):
		var star_entry := _stars[id] as Dictionary
		var system_entry := star_entry.system as StarSystemRecord

		## TODO: also update .system?

		## update timeout
		if expire_tick > star_entry.expire_tick:
			star_entry.expire_tick = expire_tick

		if system_entry.name.is_empty() && !star_system.name.is_empty():
			system_entry.name = star_system.name
			print("Found name for %d: %s" % [system_entry.id, system_entry.name])

		## TODO: "Scan" events in multi-star systems change classes. Select main star.
		#if star_system.star_class != &"" && star_system.star_class != system_entry.star_class:
		if system_entry.star_class == &"" && star_system.star_class != &"":
			print("Star class changed: %s %s -> %s" % [star_system.name, system_entry.star_class, star_system.star_class])
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
	star.modulate = color

	## TODO: define record type
	var star_entry := {
		"system": star_system,
		"star": star,
		"expire_tick": expire_tick
	}

	_stars[star_system.id] = star_entry;

	add_child(star)
	counter.emit(len(_stars))


func delete_id(id: int) -> void:
	if id in _stars:
		if _stars[id] is Dictionary:
			var star_entry := _stars[id] as Dictionary
			if is_instance_of(star_entry.get("star"), Node):
				(star_entry.star as Node).queue_free()
		_stars.erase(id)
#		counter.emit(len(_stars))


func expire() -> int:
	var now := Time.get_ticks_msec()
	var count : int = 0

	for star_key in _stars.keys():
		var star_entry := _stars[star_key] as Dictionary
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
