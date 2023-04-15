#class_name EDDNReceiver
extends Node


## TODO: directly connected event nodes could subscribe to event types instead of signals
## TODO: use call_group() to distribute message?
## TODO: extract uploader ID to link jumps?
## TODO: select live/legacy, update UI
## TODO: parse all commonly used information into typed class?


## Maximum accepted difference in seconds between local time and event timestamp.
@export var cut_off : int = 3600


## Emitted when an EDDN event was received.
signal received(event_type: StringName, message: Dictionary, star_system: StarSystemRecord, age: int)


func _on_json_web_socket_receiver_received(data: Dictionary) -> void:
	#var schema := data.get("$schemaRef") as String
	#var header := data.get("header") as Dictionary

	var _message = data.get("message")
	if !(_message is Dictionary):
		print("EDDN data contains no message")
		return
	var message := _message as Dictionary

	var _ts = message.get("timestamp")
	if !(_ts is String):
		print("EDDN message contains no timestamp")
		return

	var ts := Time.get_unix_time_from_datetime_string(_ts)
	if ts == 0:
		print("EDDN message contains invalid timestamp")
		return

	var age := (Time.get_unix_time_from_system() as int) - ts;
	if age > cut_off:
		pass
		## ignore old data
		#return

	var _event_type = message.get("event")
	if _event_type is String && _event_type != "":
		## TODO: does event_type StringName interning accumulate garbage? (flood with random event types?)
		var event_type := StringName(_event_type)

		received.emit(event_type, message, StarSystemRecord.parse(message), age)

#		var system_id = message.get("SystemAddress")
#		var starpos = message.get("StarPos")
#
#		if !((system_id is int || system_id is float) &&
#				(starpos is Array && len(starpos) == 3) &&
#				(starpos[0] is float) && (starpos[1] is float) && (starpos[2] is float)):
#
#			## NavRoute, FCMaterials, ...? don't carry system location
#			if event_type not in [&"NavRoute", &"FCMaterials"]:
#				print("EDDN event without system address: %s" % event_type)
#				## TODO: whitelist events and return here?
#				#return
#
#			system_id = -1 ## arbitrary dummy ID. TODO: does ID int(-1) exist?
#			starpos = [0.0, 100e3, 0.0] ## arbitrary dummy location. TODO: use [0,0,0]?
#		received.emit(event_type, message, system_id as int, Vector3(starpos[0], starpos[1], starpos[2]))
	else:
		## market/shipyard/outfitting updates also end up here
		#received.emit("Event", message)
		#print(message)
		pass
