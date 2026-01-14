extends Button

@onready var tital = $Title
@onready var image = $Image
@onready var value = $value

func _ready() -> void:
	self.focus_entered.connect(_on_focus_entered)

func set_butt_action(icon_texture: Texture, name: String ,num: int):
	# ตั้งค่ารูปภาพและตัวเลขตามที่ได้รับมา
	image.texture = icon_texture
	tital.text = name
	value.text = str(num)

func _on_focus_entered():
	var scroll_container = get_parent().get_parent()
	if scroll_container is ScrollContainer:
		# เรียกฟังก์ชันช่วยเลื่อนใน ScrollContainer
		_smooth_scroll_to_self(scroll_container)

func _smooth_scroll_to_self(sc: ScrollContainer):
	# ระยะขอบ (Margin) เพื่อไม่ให้ปุ่มชิดขอบบน/ล่างเกินไป
	var margin = 20 
	
	# ตำแหน่งด้านบนและด้านล่างของปุ่มนี้เทียบกับ VBox
	var button_top = self.position.y
	var button_bottom = button_top + self.size.y
	
	# ขอบเขตที่มองเห็นได้ในปัจจุบันของ ScrollContainer
	var view_top = sc.scroll_vertical
	var view_bottom = view_top + sc.size.y
	
	# สร้าง Tween เพื่อให้การเลื่อนดูนุ่มนวล (Smooth Scroll)
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	if button_bottom > view_bottom - margin:
		# ถ้าปุ่มอยู่ใกล้ขอบล่าง ให้เลื่อน Scroll ลงเพื่อให้เห็นปุ่มชัดขึ้น
		var target_scroll = button_bottom - sc.size.y + margin
		tween.tween_property(sc, "scroll_vertical", target_scroll, 0.2)
	
	elif button_top < view_top + margin:
		# ถ้าปุ่มอยู่ใกล้ขอบบน ให้เลื่อน Scroll ขึ้น
		var target_scroll = button_top - margin
		tween.tween_property(sc, "scroll_vertical", target_scroll, 0.2)
