extends Label


func _process(delta: float) -> void:
	var camera_position := get_viewport().get_camera_3d().position
	text = "%.2f, %.2f, %2.f" % [-camera_position.x, camera_position.y, camera_position.z]  ## Adjust camera x to ED galaxy
