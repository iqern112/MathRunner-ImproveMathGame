extends Control
class_name route_selection

@onready var numpad_button = $"../NumpadPanel/GridContainer/1"
@onready var desc_label = $Panel/DescriptionLabel
@onready var route_icon = $"../Route/RouteIcon"
var current_options = []

# ข้อมูล Route ทั้งหมด
var data_routes = {
	"Monster": {"title": "Battle", "desc": "Fight against a random monster.", "icon": preload("res://Resouce/RouteIcon/MonsterIcon.tres")},
	"Shop": {"title": "Shop", "desc": "Visit the merchant to buy items.", "icon": preload("res://Resouce/RouteIcon/ShopIcon.tres")},
	"Camp": {"title": "Camp", "desc": "Rest to recover your HP.", "icon": preload("res://Resouce/RouteIcon/CampIcon.tres")},
	"Elite": {"title": "Elite Battle", "desc": "Stronger enemy, better rewards.", "icon": preload("res://Resouce/RouteIcon/EliteIcon.tres")},
	"Event": {"title": "Mystery Event", "desc": "Something unexpected might happen.", "icon": preload("res://Resouce/RouteIcon/EventIcon.tres")},
	"Treasure": {"title": "Treasure", "desc": "Find a chest full of gold.", "icon": preload("res://Resouce/RouteIcon/TreasureIcon.tres")},
	"Boss": {"title": "Boss", "desc": "The final challenge.", "icon": preload("res://Resouce/RouteIcon/BossIcon.tres")},
}

func _ready() -> void:
	$Panel/RouteButtonsContainer/Button.pressed.connect(_on_route_selected.bind(0))
	$Panel/RouteButtonsContainer/Button2.pressed.connect(_on_route_selected.bind(1))
	$Panel/RouteButtonsContainer/Button3.pressed.connect(_on_route_selected.bind(2))

	$Panel/RouteButtonsContainer/Button.focus_entered.connect(_show_desc.bind(0))
	$Panel/RouteButtonsContainer/Button2.focus_entered.connect(_show_desc.bind(1))
	$Panel/RouteButtonsContainer/Button3.focus_entered.connect(_show_desc.bind(2))

# ฟังก์ชันสำหรับสุ่ม Route ขึ้นมาโชว์
func open_route_picker():
	var keys = data_routes.keys()
	keys.erase("Boss") # ยังไม่ให้สุ่มเจอบอสในทางเดินปกติ
	keys.shuffle()
	current_options = keys.slice(0, 3)
	
	# อัปเดตรูปไอคอนบนปุ่ม
	$Panel/RouteButtonsContainer/Button/NinePatchRect.texture = data_routes[current_options[0]]["icon"]
	$Panel/RouteButtonsContainer/Button2/NinePatchRect.texture = data_routes[current_options[1]]["icon"]
	$Panel/RouteButtonsContainer/Button3/NinePatchRect.texture = data_routes[current_options[2]]["icon"]

	get_tree().paused = true # หยุดเกมเพื่อเลือกทาง
	$Panel.visible = true
	await get_tree().process_frame
	$Panel/RouteButtonsContainer/Button.grab_focus()

func _show_desc(index: int):
	var route_key = current_options[index] 
	var data = data_routes[route_key]
	desc_label.text = data["title"] + "\n" + data["desc"]

func _on_route_selected(index: int):
	var selected_route = current_options[index]
	
	# --- ส่วนที่เพิ่มใหม่: เปลี่ยนไอคอนที่หน้าจอหลัก ---
	# ดึงข้อมูลข้อมูลเส้นทางที่เลือก (เช่น รูปภาพ) จาก data_routes
	var selected_data = data_routes[selected_route]
	
	# ตรวจสอบว่ามีโหนด route_icon หรือไม่ และเปลี่ยน texture
	if route_icon:
		# สมมติว่า route_icon เป็น Sprite2D หรือ TextureRect
		# หากเป็นโหนดประเภทอื่นที่ครอบ NinePatchRect ให้แก้เป็น route_icon.get_node("NinePatchRect").texture
		route_icon.texture = selected_data["icon"]
	$Panel.visible = false
	get_tree().paused = false
	GameEvents.route_selected.emit(selected_route)
	
	if numpad_button: 
		await get_tree().process_frame # รอให้ UI ปิดสนิทก่อนคืนโฟกัส
		numpad_button.grab_focus()
