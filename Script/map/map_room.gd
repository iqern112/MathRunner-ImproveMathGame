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

@onready var sprite_2d: Sprite2D = $Sprite2D
#@onready var line_2d: Line2D = $Visuals/Line2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var available := false : set = set_available
var room: Room : set = set_room

func set_available(new_value: bool) -> void:
	available = new_value
	if available:
		animation_player.play("highlight")
	elif not room.selected:
		animation_player.play("RESET")

func set_room(new_data: Room) -> void:
	room = new_data
	position = room.position
	
	# เพิ่มส่วนนี้เข้าไปเพื่อให้ Icon เปลี่ยนตามประเภทห้อง
	if is_inside_tree(): # ตรวจสอบว่า Node พร้อมทำงานหรือยัง
		_update_visuals()

# สร้างฟังก์ชันแยกไว้สำหรับอัปเดตรูปภาพ
func _update_visuals() -> void:
	var icon_data = ICONS.get(room.type)
	if icon_data:
		sprite_2d.texture = icon_data[0]
		sprite_2d.scale = icon_data[1]

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not available or not event.is_action_pressed("left_mouse"):
		return
	
	room.selected = true
	animation_player.play("select")


# Called by the AnimationPlayer when the
# "select" animation finishes.
func _on_map_room_selected() -> void:
	selected.emit(room)
