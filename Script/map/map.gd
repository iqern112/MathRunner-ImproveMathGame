class_name Map
extends Node2D

const SCROLL_SPEED := 5
const MAP_ROOM = preload("res://Scene/map/map_room.tscn")
const MAP_LINE = preload("res://Scene/map/map_line.tscn")
const START_OFFSET_Y := 20.0

@onready var map_generator: MapGenerator = $map_generator
@onready var lines: Node2D = $Visuals/Lines
@onready var rooms: Node2D = $Visuals/Rooms
@onready var visuals: Node2D = $Visuals
@onready var camera_2d: Camera2D = $Camera2D

var map_data: Array[Array]
var floors_climbed: int
var last_room: Room
var camera_edge_y: float

var target_y := 0.0

func _ready() -> void:
	generate_new_map()
	
	# คำนวณความสูงจริงของแผนที่ (จากแถวแรกถึงแถวสุดท้าย)
	var total_map_height = MapGenerator.Y_DIST * (MapGenerator.FLOORS - 1)
	
	# คำนวณขอบบน: คือความสูงแผนที่ ลบด้วยพื้นที่ว่างที่เหลือด้านบนหน้าจอ
	# เพื่อให้ห้องบอสเลื่อนขึ้นมาหยุดตรงขอบบนพอดี
	var view_height = get_viewport_rect().size.y
	camera_edge_y = total_map_height - (view_height * 0.8) # 0.1 ล้อตาม 0.9 ของ visuals.y
	
	# ป้องกันค่าติดลบกรณีแผนที่สั้นกว่าหน้าจอ
	camera_edge_y = max(0, camera_edge_y)
	
	unlock_floor(0)
	target_y = START_OFFSET_Y
	camera_2d.position.y = START_OFFSET_Y


func _process(delta: float) -> void:
	var scroll_input := 0.0
	
	if Input.is_action_pressed("ui_text_scroll_up"):
		scroll_input -= 1.0
	if Input.is_action_pressed("ui_text_scroll_down"):
		scroll_input += 1.0
	
	if scroll_input != 0:
		target_y += scroll_input * SCROLL_SPEED * delta * 50.0
	
	target_y = clamp(target_y, -camera_edge_y, START_OFFSET_Y)
	
	# ใช้ lerp เพียงครั้งเดียวและเก็บค่าไว้
	var new_y = lerp(camera_2d.position.y, target_y, 0.15)
	
	# ปัดเศษพิกัดกล้องเพื่อความคมชัดของเส้น 1px
	camera_2d.position.y = round(new_y)

func _input(event: InputEvent) -> void:
	pass

func generate_new_map() -> void:
	floors_climbed = 0
	map_data = map_generator.generate_map()
	create_map()

func create_map() -> void:
	for current_floor: Array in map_data:
		for room: Room in current_floor:
			if room.next_rooms.size() > 0:
				_spawn_room(room)
	
	# Boss room has no next room but we need to spawn it
	var middle := floori(MapGenerator.MAP_WIDTH * 0.5)
	_spawn_room(map_data[MapGenerator.FLOORS-1][middle])
	
	var map_width_pixels := MapGenerator.X_DIST * (MapGenerator.MAP_WIDTH - 1)
	visuals.position.x = (get_viewport_rect().size.x - map_width_pixels) / 2
	#visuals.position.y = get_viewport_rect().size.y / 2
	visuals.position.y = get_viewport_rect().size.y * 0.9

func _spawn_room(room: Room) -> void:
	var new_map_room := MAP_ROOM.instantiate() as MapRoom
	rooms.add_child(new_map_room)
	new_map_room.room = room
	new_map_room.selected.connect(_on_map_room_selected)
	_connect_lines(room)
	
	if room.selected and room.row < floors_climbed:
		new_map_room.show_selected()

func _connect_lines(room: Room) -> void:
	if room.next_rooms.is_empty():
		return
	var center_offset := Vector2(8, 8)
	for next: Room in room.next_rooms:
		var new_map_line := MAP_LINE.instantiate() as Line2D
		new_map_line.add_point(room.position + center_offset)
		new_map_line.add_point(next.position + center_offset)
		lines.add_child(new_map_line)

func _on_map_room_selected(room: Room) -> void:
	for map_room: MapRoom in rooms.get_children():
		if map_room.room.row == room.row:
			map_room.available = false
	last_room = room
	floors_climbed += 1
	

func unlock_floor(which_floor: int = floors_climbed) -> void:
	for map_room: MapRoom in rooms.get_children():
		if map_room.room.row == which_floor:
			map_room.available = true

func unlock_next_rooms() -> void:
	for map_room: MapRoom in rooms.get_children():
		if last_room.next_rooms.has(map_room.room):
			map_room.available = true

func show_map() -> void:
	show()
	camera_2d.enabled = true

func hide_map() -> void:
	hide()
	camera_2d.enabled = false
