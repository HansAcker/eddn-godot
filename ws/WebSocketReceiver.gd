extends Node

@export var ws_url := "wss://ws.eddn-realtime.space/eddn"

## Emitted when a JSON dictionary was received
signal received(data: Dictionary)

var socket := WebSocketPeer.new()

func _ready() -> void:
	var rc := socket.connect_to_url(ws_url)
	if rc != OK:
		print("WebSocket connect error:", rc)
		# TODO: reconnect
		set_process(false)

func _process(_delta: float) -> void:
	socket.poll()

	while socket.get_available_packet_count():	
		var packet := socket.get_packet()
		var rc := socket.get_packet_error()
		if rc != OK:
			print("WebSocket received error:", rc)
			continue

		var data : Dictionary = JSON.parse_string(packet.get_string_from_utf8())
		if data == null:
			print("WebSocket data is null")
			continue

		received.emit(data.message)

	match socket.get_ready_state():
		#WebSocketPeer.STATE_CONNECTING:
		#	pass
		#WebSocketPeer.STATE_CLOSING:
		#	pass
		#WebSocketPeer.STATE_OPEN:
		#	pass
		WebSocketPeer.STATE_CLOSED:
			var code := socket.get_close_code()
			var reason := socket.get_close_reason()
			print("WebSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1])
			# TODO: reconnect
			set_process(false)
