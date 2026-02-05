extends CanvasLayer

@onready var panel = $Title/Panel
@onready var title_label = $Title/Panel/TitleLabel
@onready var desc_label = $Title/Panel/DescLabel

func _ready():
	panel.hide() # เริ่มมาให้ซ่อนไว้ก่อน

# ฟังก์ชันแสดงข้อมูล
func show_info(title: String, desc: String ):
	title_label.text = title
	desc_label.text = desc
	panel.show()

# ฟังก์ชันซ่อน
func hide_info():
	panel.hide()
