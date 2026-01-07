extends Control


func _on_re_game_pressed() -> void:
	get_tree().paused = false
	# 2. เริ่มเกมใหม่
	get_tree().reload_current_scene()

func game_over(): 
	get_tree().paused = true 
	$"../..".stop_game()
	$".".visible = true
