extends MultiMeshInstance3D


## Fluff up the galaxy with colored multimesh instances.
##
## TODO: look closer at Canonn's Method: getHeightData in
##       https://github.com/canonn-science/CanonnED3D-Map/blob/master/Source/js/components/galaxy.class.js#L258


func _ready():
	## TODO: get texture from parent?
	var image: Image = load("res://Stars/textures/galaxy.jpg").get_image()
	var size := image.get_size()

	## TODO: get galaxy size from parent?
	var xscale := 104000 / size.x
	var zscale := 104000 / size.y

	var instances: Array = []

	## Max. instances per pixel
	var ipp := int((104000**2) / (size.x * size.y) / 10000)
	
	## Relative distance from edges, used to scale ipp and height
	## TODO: clamp to [0, 1]? use something else?
	var edge_xy : Vector2

	## TODO: use image.get_data() and process the array instead of image.get_pixel?

	for x in range(-size.x/2, size.x/2):
		var pixel_x = x + (size.x/2)
		edge_xy.x = 1 - inverse_lerp(0.0, size.x/2, abs(x))

		for y in range(-size.y/2, size.y/2):
			var pixel_y = y + (size.y/2)
			edge_xy.y = 1 - inverse_lerp(0.0, size.y/2, abs(y))

			var pixel := image.get_pixel(pixel_x, pixel_y).srgb_to_linear()*10  ## TODO: explain scale, make configurable

#			var pixel_mean := (pixel.r + pixel.g + pixel.b) / 3
#			var pixel_lum := pixel.get_luminance()

			if pixel == Color.BLACK: # || pixel_lum <= 0.1:
#				print(Vector2(pixel_x, pixel_y), ", ", pixel)
				continue

			for i in range(0, ipp * edge_xy.length()):
				var pos_x := (randf()-0.5) * xscale
				var pos_z := (randf()-0.5) * zscale
				var pos_y := randfn(0.0, 0.5) * 5_000.0 * edge_xy.length()  ## TODO: proper distribution

				var pos := Transform3D(Basis(), Vector3(pos_x + (xscale * x), pos_y, pos_z + (zscale * y)))
				instances.push_back([pos, pixel])

	print("Galaxy fluff multimesh instance count: %d" % len(instances))

	multimesh.instance_count = len(instances)
	for i in range(0, len(instances)):
		multimesh.set_instance_color(i, instances[i][1])
		multimesh.set_instance_transform(i, instances[i][0])
