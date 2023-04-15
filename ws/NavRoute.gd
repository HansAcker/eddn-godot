extends Node

## Expire time in seconds. 0 to keep forever.
@export var expire: int = 0

@onready var star_manager := get_node("../../../Map/StarManager") as StarManager

func _on_eddn_receiver_received(event_type: StringName, message: Dictionary, _star_system: StarSystemRecord, _age: int) -> void:
	if event_type != &"NavRoute":
		return

	var route = message.get("Route")
	if !(route is Array):
		print("NavRoute contains no Route")
		return

	for wp in route:
		star_manager.add(StarSystemRecord.parse(wp), expire * 1000)
