extends NinePatchRect
#ItemOnShow.gd

@onready var stack_label = $Label

func set_item_info(icon_texture: Texture, count: int):
	# ตั้งค่ารูปภาพและตัวเลขตามที่ได้รับมา
	texture = icon_texture
	stack_label.text = str(count)
