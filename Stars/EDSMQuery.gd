extends Node


## Adds stars from EDSM systems API
## TODO: quick hack. Think again.
## TODO: maybe add edsm_parse_* to StarSystemRecord?
## TODO: await what?
## TODO: map EDSM star classes (Neutron -> N, etc.)


## EDSM API base URL. E.g. https://www.edsm.net
@export var edsm_api_base : String = "https://www.edsm.net"
#@export var edsm_api_base : String = "https://test.eddn-realtime.space/.edsmcache"

## Radius of search sphere in ly
@export var query_radius : int = 20

## Minimum distance in ly
@export var min_radius : int = 0

## Expire time in seconds. 0 to keep forever.
@export var expire: int = 0:
	set(value):
		expire = value
		_expire_msec = value * 1000


@onready var http_request = HTTPRequest.new()

@onready var star_manager := get_node("../StarManager") as StarManager

var _expire_msec : int


func _ready() -> void:
	add_child(http_request)
	http_request.request_completed.connect(self._http_request_completed)

func add_stars_at(position: Vector3) -> void:
	var center := Vector3(snappedf(-position.x, query_radius / 2.0), snappedf(position.y, query_radius / 2.0), snappedf(position.z, query_radius / 2.0))
	print("EDSM query center: %s" % center)
	var error = http_request.request(edsm_api_base + "/api-v1/sphere-systems?x=%s&y=%s&z=%s&radius=%d&minRadius=%d&showId=1&showCoordinates=1&showPrimaryStar=1" %
			["%.5f" % center.x, "%.5f" % center.y, "%.5f" % center.z, query_radius, min_radius])
	if error != OK:
		push_error("An error occurred in the HTTP request.")

func _http_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	var json = JSON.new()
	json.parse(body.get_string_from_utf8())
	var _response = json.get_data()
	if !(_response is Array):
		print("not an Array")
		return

	var response := _response as Array

	for _sys in response:
		var sys_entry := StarSystemRecord.new()

		if !(_sys is Dictionary):
			print("not a Dictionary")
			continue
		var sys := _sys as Dictionary

		var id = sys.get("id64")
		if !(id is int || id is float):
			print("no ID: %s" % sys)
			continue
		sys_entry.id = id

		var name = sys.get("name")
		if !(name is String):
			print("no name")
			continue
		sys_entry.name = name

		var _coords = sys.get("coords")
		if !(_coords is Dictionary):
			print("no coords")
			continue
		var coords := _coords as Dictionary
		var x = coords.get("x")
		if !(x is float):
			print("wrong coords")
			continue
		var y = coords.get("y")
		if !(y is float):
			print("wrong coords")
			continue
		var z = coords.get("z")
		if !(z is float):
			print("wrong coords")
			continue
		sys_entry.position = Vector3(-x, y, z)

		var count : int = 0

		var _primary = sys.get("primaryStar")
		if _primary is Dictionary:
			var primary := _primary as Dictionary
			var _star_class = primary.get("type")
			if _star_class is String:
				var star_class := (_star_class as String).split(" ", false, 1)[0]
				if !(star_class in StarClasses.colors):
					print("no color for star_class %s (%s)" % [star_class, _star_class])
					sys_entry.star_class = &""
				else:
					sys_entry.star_class = StringName(star_class)

#		print("adding %s at %s" % [sys_entry.name, sys_entry.position])
		star_manager.add(sys_entry, _expire_msec, 1.0, false)
		
		count += 1
		if count >= 1:  ## TODO: values > 1 don't submit stars in batches as expected
			await get_tree().physics_frame
			count = 0
