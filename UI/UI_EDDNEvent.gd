extends Control


@onready var type_label := $Type as Label
@onready var system_label := $SystemName as Label
@onready var position_label := $Position as Label
@onready var ts_label := $Timestamp as Label

var jumps : int = 0


func _on_eddn_receiver_received(event_type: StringName, message: Dictionary, star_system: StarSystemRecord, age: int) -> void:
	if event_type == &"FSDJump" && age < 60:
		jumps += 1

	type_label.text = event_type
	system_label.text = star_system.name
	position_label.text = "x: %10.3fly y: %10.3fly z: %10.3fly" % [-star_system.position.x, star_system.position.y, star_system.position.z] if star_system.position != StarSystemRecord.POS_INVALID else ""
	ts_label.text = "%s (%ss ago), %.1f jumps per minute" % [message.timestamp, age, (jumps as float) / (Time.get_ticks_msec() as float) * 1000.0 * 60.0]


func _on_json_web_socket_receiver_disconnected(code: int, reason: String) -> void:
	type_label.text = "WebSocket closed with code: %d, reason: %s. Clean: %s" % [code, reason, code != -1]
	system_label.text = ""
