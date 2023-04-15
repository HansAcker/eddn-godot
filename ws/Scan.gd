extends Node


@onready var star_manager := get_node("../../../Map/StarManager") as StarManager

func _on_eddn_receiver_received(event_type: StringName, _message: Dictionary, star_system: StarSystemRecord, _age: int) -> void:
	if event_type != &"Scan":
		return

	## TODO: use message contents to add more stuff

	if star_system.star_class != &"":
		star_manager.add(star_system)
