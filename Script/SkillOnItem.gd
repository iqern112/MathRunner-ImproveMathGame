# SkillItem.gd
extends NinePatchRect

@onready var stack_label = $Label

func set_skill_info(icon_texture: Texture, count: int):
	# ตั้งค่ารูปภาพและตัวเลขตามที่ได้รับมา
	texture = icon_texture
	stack_label.text = str(count)
	if count > 1:
		stack_label.visible = true
	else:
		stack_label.visible = false # ซ่อนไว้ถ้ามีแค่ 1 อัน (เลเวล 1)
