extends Node


## Adds stars for all events with a position.
## TODO: filter events already handled elsewhere


## Expire time in seconds. 0 to keep forever.
@export var expire: int = 0


@onready var star_manager := get_node("../../../Map/StarManager") as StarManager

func _on_eddn_receiver_received(event_type: StringName, _message: Dictionary, star_system: StarSystemRecord, age: int) -> void:
	if star_system.position != StarSystemRecord.POS_INVALID:
		if star_system.name.is_empty():
			#print(_message)
			print("Empty name for %s in %d %s" % [event_type, star_system.id, star_system.position])

		## TODO: configurable alpha scale
		star_manager.add(star_system, expire * 1000, 1.0 - (clampi(age, 0, 3600) / 4000.0) if age > 10 else 1.0)
