extends Node


## Adds stars from EDSM systems API
## TODO: quick hack. Think again.
## TODO: maybe add edsm_parse_* to StarSystemRecord?
## TODO: await what?
## TODO: map EDSM star classes (Neutron -> N, etc.)


## EDSM API base URL. E.g. https://www.edsm.net
#@export var edsm_api_base : String = "https://www.edsm.net"
@export var edsm_api_base : String = "https://test.eddn-realtime.space/.edsmcache"

## Snap center position to multiples of this value.
@export var location_precision : float = 1.0

## Radius of search sphere in ly.
@export var radius : int = 20

## Minimum distance from center in ly.
@export var min_radius : int = 0

## Expire time in seconds. 0 to keep forever.
@export var expire: int = 0:
	set(value):
		expire = value
		_expire_msec = value * 1000


var _expire_msec : int

var http_request := HTTPRequest.new()

@onready var star_manager := get_node("../StarManager") as StarManager
#@onready var Log := get_node("../../UI/Log")


func _ready() -> void:
	add_child(http_request)
	http_request.request_completed.connect(_http_request_completed)


func add_stars_at(position: Vector3) -> void:
	var center := Vector3(snappedf(-position.x, location_precision), snappedf(position.y, location_precision), snappedf(position.z, location_precision))
	print("EDSM query center: %s" % center)

	var error := http_request.request(edsm_api_base + "/api-v1/sphere-systems?x=%s&y=%s&z=%s&radius=%d&minRadius=%d&showId=1&showCoordinates=1&showPrimaryStar=1" %
			["%.5f" % center.x, "%.5f" % center.y, "%.5f" % center.z, radius, min_radius])
	if error != OK:
		push_error("EDSM query error in the HTTP request.")


func _http_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	## TODO: maybe extract X-Rate-Limit-Limit, -Remaining, -Reset
#	print("EDSM response: result %d, rc %d" % [result, response_code])
#	print(headers)

	var json := JSON.new()
	var rc := json.parse(body.get_string_from_utf8())
	if rc != OK:
		push_error("ESDM response: JSON parse error: ", rc)
		return

	var _response = json.get_data()
	if !(_response is Array):
		push_warning("EDSM query returned no data")
#		Log.print("EDSM query returned no data")
		return

	var response := _response as Array
	var count: int = 0

	for _sys in response:
		if !(_sys is Dictionary):
			push_error("EDSM response: array member not a Dictionary")
			continue

		var sys := _sys as Dictionary
		var sys_entry := StarSystemRecord.new()

		var id = sys.get("id64")
		if !(id is int || id is float):
			push_error("EDSM response: no id64 in %s" % sys)
			continue
		sys_entry.id = id

		var sys_name = sys.get("name")
		if !(sys_name is String):
			push_error("EDSM response: no name in %s" % sys)
			continue
		sys_entry.name = sys_name

		var _coords = sys.get("coords")
		if !(_coords is Dictionary):
			push_error("EDSM response: no coords in %s" % sys)
			continue

		var coords := _coords as Dictionary

		var x = coords.get("x")
		if !(x is float):
			push_error("EDSM response: invalid coords in %s" % sys)
			continue

		var y = coords.get("y")
		if !(y is float):
			push_error("EDSM response: invalid coords in %s" % sys)
			continue

		var z = coords.get("z")
		if !(z is float):
			push_error("EDSM response: invalid coords in %s" % sys)
			continue

		sys_entry.position = Vector3(-x, y, z)

		var _primary = sys.get("primaryStar")
		if _primary is Dictionary:
			var primary := _primary as Dictionary
			var _star_class = primary.get("type")
			if _star_class is String:
				var star_class := (_star_class as String).split(" ", false, 1)[0]
				## TODO: comparing String vs StringName. fix mapping from EDSM names.
				if !(star_class in StarClasses.colors):
					push_warning("EDSM response: no color for star class %s (%s)" % [star_class, _star_class])
					sys_entry.star_class = &""
				else:
					sys_entry.star_class = StringName(star_class)

#		print("adding %s at %s" % [sys_entry.name, sys_entry.position])
		star_manager.add(sys_entry, _expire_msec, 1.0, false, false)

		count += 1

	print("EDSM added %d stars" % count)
#	Log.print("EDSM added %d stars" % count)
