extends Label


func _on_star_manager_counter(count: int, meshed: int) -> void:
	text = "%d active stars, %d meshed" % [count, meshed]
