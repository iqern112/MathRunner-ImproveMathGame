extends Control

@onready var restart_button = $VBoxContainer/Restart

func _ready() -> void:
	GameEvents.game_over_triggered.connect(game_over)
	visibility_changed.connect(_on_visibility_changed)

func game_over():
	await get_tree().create_timer(1).timeout
	$".".visible = true

func _on_visibility_changed():
	if visible:
		# ใช้ grab_focus() เพื่อให้ปุ่ม Restart ถูกเลือกอัตโนมัติ
		restart_button.grab_focus()

# ฟังก์ชันสำหรับปุ่ม Restart (ถ้ายังไม่ได้เขียน)
func _on_restart_pressed() -> void:
	#get_tree().paused = false # อย่าลืมปลดล็อค Pause ก่อนเริ่มใหม่
	get_tree().reload_current_scene()
