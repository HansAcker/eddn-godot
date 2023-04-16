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
var last_message
var receive_timer := Timer.new()
func reconnect() -> void:
	receive_timer.stop()
	print("reconnect. last message was: ", last_message)
	_socket = WebSocketPeer.new()
	_connected = false
	_ws_connect()


func _retry() -> void:
	## TODO: only a single timer should run
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
	receive_timer.one_shot = true
	receive_timer.wait_time = 12.3
	receive_timer.timeout.connect(reconnect)
	add_child(receive_timer)
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
			receive_timer.stop()
			received.emit(data)
			receive_timer.start()
		else:
			print("WebSocket received invalid data")

		last_message = data

	match _socket.get_ready_state():
		WebSocketPeer.STATE_CONNECTING:
			pass
		WebSocketPeer.STATE_CLOSING:
			pass
		WebSocketPeer.STATE_OPEN:
			if !_connected:
				print("WebSocket connected.")
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
