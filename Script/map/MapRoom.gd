class_name MapRoom
extends Button

signal selected(room: Room)

const ICONS := {
	Room.Type.MONSTER: [preload("res://Resouce/RouteIcon/MonsterIcon.tres"), Vector2.ONE],
	Room.Type.ELITE: [preload("res://Resouce/RouteIcon/EliteIcon.tres"), Vector2.ONE],
	Room.Type.EVENT: [preload("res://Resouce/RouteIcon/EventIcon.tres"), Vector2.ONE],
	Room.Type.SHOP: [preload("res://Resouce/RouteIcon/ShopIcon.tres"), Vector2.ONE],
	Room.Type.CAMPFIRE: [preload("res://Resouce/RouteIcon/CampIcon.tres"), Vector2.ONE],
	Room.Type.BOSS: [preload("res://Resouce/RouteIcon/BossIcon.tres"), Vector2.ONE],
	Room.Type.TREASURE: [preload("res://Resouce/RouteIcon/TreasureIcon.tres"), Vector2.ONE],
}

const AVAILABLE_BUTT = preload("res://Theme/ButtomPixelStye.tres")
var empty_style = StyleBoxEmpty.new()

@onready var sprite_2d: Sprite2D = $Sprite2D

var available := false : set = set_available
var room: Room : set = set_room


# แก้ไขฟังก์ชัน set_available
func set_available(new_value: bool) -> void:
	available = new_value
	if available:
		# เมื่อห้องพร้อม ให้เปิดการทำงานของปุ่ม
		disabled = false
		focus_mode = FOCUS_ALL # อนุญาตให้รับโฟกัส
		add_theme_stylebox_override("normal", AVAILABLE_BUTT)
	else:
		# เมื่อห้องยังไปไม่ถึง ให้ปิดการทำงาน
		disabled = true
		focus_mode = FOCUS_NONE # ไม่ให้โฟกัสไปตกที่ปุ่มนี้
		add_theme_stylebox_override("normal", empty_style)
		add_theme_stylebox_override("disabled", empty_style)

func set_room(new_data: Room) -> void:
	room = new_data
	position = room.position
	
	# เพิ่มส่วนนี้เข้าไปเพื่อให้ Icon เปลี่ยนตามประเภทห้อง
	if is_node_ready():
		_update_visuals()
		set_available(available)

# สร้างฟังก์ชันแยกไว้สำหรับอัปเดตรูปภาพ
func _update_visuals() -> void:
	var icon_data = ICONS.get(room.type)
	if icon_data:
		sprite_2d.texture = icon_data[0]
		sprite_2d.scale = icon_data[1]

func _pressed() -> void:
	if not available:
		return
	selected.emit(room)


# Called by the AnimationPlayer when the
# "select" animation finishes.
#func _on_map_room_selected() -> void:
	#selected.emit(room)
