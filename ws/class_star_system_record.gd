class_name StarSystemRecord


## Basic star system information
## Static functions to parse data from EDDN message


## TODO: is is_equal_approx() required to compare positions to POS_INVALID?
const POS_INVALID := Vector3(0.0, 100e3, 0.0) ## arbitrary dummy location. TODO: use something else?

var name: String
var id: int  ## ED id64 field
var star_class: StringName  ## Main star class
var position: Vector3


static func parse_system_name(from: Dictionary) -> String:
	## TODO: StarSystem vs SystemName vs System. consult EDDN documentation.
	var system_name = from.get("StarSystem")
	if (system_name is String || system_name is StringName):
		return system_name as String

	system_name = from.get("SystemName")
	if (system_name is String || system_name is StringName):
		return system_name as String

	system_name = from.get("System")
	if (system_name is String || system_name is StringName):
		return system_name as String

	return ""

static func parse_system_id(from: Dictionary) -> int:
	var system_id = from.get("SystemAddress")
	if !(system_id is int || system_id is float):
		return -1 ## arbitrary dummy ID. TODO: does ID int(-1) exist?
	return system_id

static func parse_star_class(from: Dictionary) -> StringName:
	## TODO: StarClass vs StarType. consult EDDN documentation.
	var star_class = from.get("StarType")
	if (star_class is String || star_class is StringName):
		return StringName(star_class)

	star_class = from.get("StarClass")
	if (star_class is String || star_class is StringName):
		return StringName(star_class)

	return &""

static func parse_starpos(from: Dictionary) -> Vector3:
	var starpos = from.get("StarPos")
	if !(starpos is Array && len(starpos) == 3 &&
			(starpos[0] is float) && (starpos[1] is float) && (starpos[2] is float)):
		return POS_INVALID
	return Vector3(-starpos[0], starpos[1], starpos[2])  ## +x in ED is -x in this world

static func parse(from: Dictionary) -> StarSystemRecord:
	var star_system := StarSystemRecord.new()

	star_system.name = parse_system_name(from)
	star_system.id = parse_system_id(from)
	star_system.star_class = parse_star_class(from)
	star_system.position = parse_starpos(from)

	return star_system
