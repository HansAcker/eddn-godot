extends Control


func _on_eddn_receiver_received(event_type: StringName, message: Dictionary, star_system: StarSystemRecord, age: int) -> void:
	($Type as Label).text = event_type
	($SystemName as Label).text = star_system.name
	($Position as Label).text = "x: %10.3fly y: %10.3fly z: %10.3fly" % [-star_system.position.x, star_system.position.y, star_system.position.z] if star_system.position != StarSystemRecord.POS_INVALID else ""
	($Timestamp as Label).text = "%s (%ss ago)" % [message.timestamp, age]

func _on_json_web_socket_receiver_disconnected(code: int, reason: String) -> void:
	($Type as Label).text = "WebSocket closed with code: %d, reason: %s. Clean: %s" % [code, reason, code != -1]
	($SystemName as Label).text = ""
