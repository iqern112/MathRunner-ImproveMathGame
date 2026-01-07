extends Control


func _on_re_game_pressed() -> void:
	get_tree().paused = false
	# 2. เริ่มเกมใหม่
	get_tree().reload_current_scene()
	
