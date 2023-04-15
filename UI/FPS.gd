extends Label


func _process(delta: float):
	text = "%6.2fms / %4.0ffps" % [delta * 1000.0, Engine.get_frames_per_second()]
