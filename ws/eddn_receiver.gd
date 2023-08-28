#class_name EDDNReceiver
extends Node


## TODO: directly connected event nodes could subscribe to event types instead of signals
## TODO: use call_group() to distribute message?
## TODO: extract uploader ID to link jumps?
## TODO: select live/legacy, update UI
## TODO: parse all commonly used information into typed class?


## Maximum accepted difference in seconds between local time and event timestamp.
## Set to -1 to disable
@export var cut_off : int = -1:
	set(value):
		if value < 0:
			value = -1
		cut_off = value
		update_configuration_warnings()

## Offset added to local time.
@export var clock_fudge : int = 0


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
		print("EDDN message contains invalid timestamp: %s" % _ts)
		return

	var age := (ceilf(Time.get_unix_time_from_system()) as int) + clock_fudge - ts;
	if cut_off >= 0 && age > cut_off:
		## ignore old data
		return

	var _event_type = message.get("event")
	if _event_type is String && _event_type != "":
		## TODO: does event_type StringName interning accumulate garbage? (flood with random event types?)
		var event_type := StringName(_event_type)

		received.emit(event_type, message, StarSystemRecord.parse(message), age)
	else:
		## market/shipyard/outfitting updates also end up here
		#received.emit("Event", message)
		#print(message)
		pass
