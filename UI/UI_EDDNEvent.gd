extends Control

func _on_eddn_receiver_received(event_type: StringName, message: Dictionary, star_system: StarSystemRecord, age: int):
	$Type.text = event_type
	$SystemName.text = star_system.name
	#$Position.text = "%s" % star_system.position if star_system.position != StarSystemRecord.POS_INVALID else ""
	$Position.text = "x: %10.3fly y: %10.3fly z: %10.3fly" % [-star_system.position.x, star_system.position.y, star_system.position.z] if star_system.position != StarSystemRecord.POS_INVALID else ""
	#$Position.text = "[table][tr][th]x[/th][th]y[/th][th]z[/th][/tr][tr][td]%9.3f[/td][td]%9.3f[/td][td]%9.3f[/td][/tr][/table]" % [star_system.position.x, star_system.position.y, star_system.position.z] if star_system.position != StarSystemRecord.POS_INVALID else ""
	$Timestamp.text = "%s (%ss ago)" % [message.timestamp, age]

func _on_json_web_socket_receiver_disconnected(code: int, reason: String):
	$Type.text = "WebSocket closed with code: %d, reason: %s. Clean: %s" % [code, reason, code != -1]
	$SystemName.text = ""
