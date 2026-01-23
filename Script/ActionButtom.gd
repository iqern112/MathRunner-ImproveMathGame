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
	var margin = 20 
	var button_top = self.position.y
	var button_bottom = button_top + self.size.y
	var view_top = sc.scroll_vertical
	var view_bottom = view_top + sc.size.y
	
	# เตรียมค่าเป้าหมาย
	var target_scroll = -1
	
	if button_bottom > view_bottom - margin:
		target_scroll = button_bottom - sc.size.y + margin
	elif button_top < view_top + margin:
		target_scroll = button_top - margin

	# สร้าง Tween เฉพาะเมื่อมีการเปลี่ยนตำแหน่ง (target_scroll ไม่เท่ากับ -1)
	if target_scroll != -1:
		var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_property(sc, "scroll_vertical", target_scroll, 0.2)
