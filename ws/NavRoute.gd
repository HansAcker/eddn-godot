extends Node

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

#	var total := 0.0
	var cur := StarSystemRecord.parse(route.pop_front())

	for _wp in route:
		var wp := StarSystemRecord.parse(_wp)
#		total += (cur.position - wp.position).length()
		## TODO: check for POS_INVALID?
		## TODO: draw lines
		## TODO: configurable alpha scale
		star_manager.add(wp, expire * 1000,  1.0 - (clampi(age, 0, 3600) / 4000.0) if age > 10 else 1.0)
		cur = wp
