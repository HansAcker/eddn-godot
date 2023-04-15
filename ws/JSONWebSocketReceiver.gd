extends Node


## Receives JSON objects from a websocket server
## Emits a signal with the parsed Dictionary
##
## TODO: receive timeout watchdog
## TODO: The websocket sometimes just closes the connection while
##       get_ready_state() still returns WebSocketPeer.STATE_OPEN


## The URL of the websocket service.
@export var ws_url := "wss://ws.eddn-realtime.space/eddn"

## Connection retry delay in seconds
## TODO: exponential backoff
@export var retry_delay : float = 1.0


## Emitted when a JSON dictionary was received from the websocket.
signal received(data: Dictionary)

## TODO: quick UI hack, think again
signal disconnected(code: int, reason: String)
signal connected()


var _socket := WebSocketPeer.new()
var _connected : bool = false


## TODO: debug aid
func reconnect() -> void:
	_socket = WebSocketPeer.new()
	_ws_connect()

func _retry() -> void:
	get_tree().create_timer(retry_delay, true, true, true).timeout.connect(_ws_connect)


func _ws_connect() -> void:
	set_process(true)

	var rc := _socket.connect_to_url(ws_url)
	if rc != OK:
		_connected = false
		disconnected.emit(-1, "Connection error")
		print("WebSocket connection error: ", rc)

		_retry()
		set_process(false)


func _ready() -> void:
	_ws_connect()


func _process(_delta: float) -> void:
	_socket.poll()

	while _socket.get_available_packet_count():	
		var packet := _socket.get_packet()
		var rc := _socket.get_packet_error()
		if rc != OK:
			print("WebSocket received error: ", rc)
			continue

		## TODO: int64 values parsed as float. precision loss?
		var data = JSON.parse_string(packet.get_string_from_utf8())
		if data is Dictionary:
			received.emit(data)
		else:
			print("WebSocket received invalid data")

	match _socket.get_ready_state():
		WebSocketPeer.STATE_CONNECTING:
			pass
		WebSocketPeer.STATE_CLOSING:
			pass
		WebSocketPeer.STATE_OPEN:
			if !_connected:
				_connected = true
				connected.emit()
			pass
		WebSocketPeer.STATE_CLOSED:
			if _connected:
				var code := _socket.get_close_code()
				var reason := _socket.get_close_reason()

				_connected = false
				disconnected.emit(code, reason)
				print("WebSocket closed with code: %d, reason: %s. Clean: %s" % [code, reason, code != -1])

				_retry()
				set_process(false)
			pass
