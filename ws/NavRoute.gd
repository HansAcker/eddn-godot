extends Node


## Adds stars for systems in NavRoute events


## Expire time in seconds. 0 to keep forever.
@export var expire: int = 0:
	set(value):
		expire = value
		_expire_msec = value * 1000


@onready var star_manager := get_node("../../../Map/StarManager") as StarManager

var _expire_msec : int

func _on_eddn_receiver_received(event_type: StringName, message: Dictionary, _star_system: StarSystemRecord, age: int) -> void:
	if event_type != &"NavRoute":
		return

	var route = message.get("Route")
	if !(route is Array || len(route) < 2):
		print("NavRoute contains no Route")
		return

	## TODO: configurable alpha scale
	var alpha := 1.0 - (clampi(age, 0, 2800) / 4000.0) if age > 10 else 1.0
	route[0].event = &"NavRoute From"
	route[len(route)-1].event = &"NavRoute To"
#	var line : Array[Vector3] = [StarSystemRecord.parse(route[0]).position]

	for _wp in route:
		var wp := StarSystemRecord.parse(_wp)
#		line.push_back(wp.position)
		## TODO: check for POS_INVALID?
		star_manager.add(wp, _expire_msec,  alpha)

	## TODO: draw lines
#	print("Line: ", line)
