extends Node


## Adds stars for systems in NavRoute events


## Expire time in seconds. 0 to keep forever.
@export var expire: int = 0

@onready var star_manager := get_node("../../../Map/StarManager") as StarManager

func _on_eddn_receiver_received(event_type: StringName, message: Dictionary, _star_system: StarSystemRecord, age: int) -> void:
	if event_type != &"NavRoute":
		return

	var route = message.get("Route")
	if !(route is Array || len(route) < 2):
		print("NavRoute contains no Route")
		return

	## TODO: configurable alpha scale
	var alpha := 1.0 - (clampi(age, 0, 3600) / 4000.0) if age > 10 else 1.0

#	var line : Array[Vector3] = [StarSystemRecord.parse(route[0]).position]

	for _wp in route:
		var wp := StarSystemRecord.parse(_wp)
#		line.push_back(wp.position)
		## TODO: check for POS_INVALID?
		star_manager.add(wp, expire * 1000,  alpha)

	## TODO: draw lines
#	print("Line: ", line)
