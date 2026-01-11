extends Button

@onready var tital = $Title
@onready var image = $Image
@onready var value = $value

func set_butt_action(icon_texture: Texture, name: String ,num: int):
	# ตั้งค่ารูปภาพและตัวเลขตามที่ได้รับมา
	image.texture = icon_texture
	tital.text = name
	value.text = str(num)
