extends Label


func _on_star_manager_counter(count: int) -> void:
	text = "%d stars" % count
