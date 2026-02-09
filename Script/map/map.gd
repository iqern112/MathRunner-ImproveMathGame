class_name Map
extends Control

const SCROLL_SPEED := 5
const MAP_ROOM = preload("res://Scene/map/MapRoom.tscn")
const MAP_LINE = preload("res://Scene/map/MapLine.tscn")
const START_OFFSET_Y := 20.0

@onready var map_generator: MapGenerator = $map_generator
@onready var lines: Node2D = $Visuals/Lines
@onready var rooms: Node2D = $Visuals/Rooms
@onready var visuals: Node2D = $Visuals
@onready var camera_2d: Camera2D = $MapCamera2D

var map_data: Array[Array]
var floors_climbed: int
var last_room: Room
var camera_edge_y: float

var target_y := 0.0

func _ready() -> void:
	GameEvents.open_map.connect(open_map)


func open_map():
	#GameEvents.open_close_nam.emit("close")
	show_map() # แสดง Node และเปิดกล้อง
	
	# ถ้าเป็นการเริ่มเกมครั้งแรก (ชั้นที่ 0) ให้ปลดล็อกชั้นแรก
	if floors_climbed == 0:
		generate_new_map() # สร้างแผนที่ใหม่ถ้ายังไม่มี
		
		# คำนวณความสูงและกล้อง (ย้ายจาก _ready มาไว้ที่นี่)
		var total_map_height = MapGenerator.Y_DIST * (MapGenerator.FLOORS - 1)
		var view_height = get_viewport_rect().size.y
		camera_edge_y = max(0, total_map_height - (view_height * 0.8))
		
		unlock_floor(0)
		target_y = START_OFFSET_Y
		camera_2d.position.y = START_OFFSET_Y
	else:
		# ถ้าไม่ใช่ชั้นแรก ให้ปลดล็อกห้องถัดไปจากห้องล่าสุดที่เลือก
		unlock_next_rooms()


func _focus_current_available_room():
	# หาห้องแรกที่เลือกได้ (available) เพื่อจับโฟกัส
	for map_room in rooms.get_children():
		if map_room.available:
			map_room.grab_focus()
			break

func _on_map_room_selected(room: Room) -> void:
	
	if floors_climbed == 0:
		#GameEvents.emit_signal("first_room_selected")
		GameEvents.cam_fade_in.emit()
		$"../../../../Player".activate_player_camera()
	# 1. จัดการเรื่อง Visual ในแผนที่ (โค้ดเดิม)
	for map_room: MapRoom in rooms.get_children():
		if map_room.room.row == room.row:
			map_room.available = false
	last_room = room
	floors_climbed += 1
	
	# 2. ส่งประเภทห้องกลับไปให้ World
	var type_string = Room.Type.keys()[room.type] 
	GameEvents.set_route(type_string)
	GameEvents.open_close_nam.emit("open")
	
	hide_map()

func _process(delta: float) -> void:
	var scroll_input := 0.0
	if $".".visible:
		if Input.is_action_pressed("map_scroll_up") or Input.is_action_pressed("ui_up"):
			scroll_input -= 1.0
		if Input.is_action_pressed("map_scroll_down") or Input.is_action_pressed("ui_down"):
			scroll_input += 1.0
		
		if scroll_input != 0:
			target_y += scroll_input * SCROLL_SPEED * delta * 50.0
		
		target_y = clamp(target_y, -camera_edge_y, START_OFFSET_Y)
		
		# ใช้ lerp เพียงครั้งเดียวและเก็บค่าไว้
		var new_y = lerp(camera_2d.position.y, target_y, 0.15)
		
		# ปัดเศษพิกัดกล้องเพื่อความคมชัดของเส้น 1px
		camera_2d.position.y = round(new_y)


func generate_new_map() -> void:
	floors_climbed = 0
	map_data = map_generator.generate_map()
	create_map()

func create_map() -> void:
	# 1. Spawn ห้องทั้งหมดก่อน
	for current_floor: Array in map_data:
		for room: Room in current_floor:
			if room.next_rooms.size() > 0:
				_spawn_room(room)
	
	var middle := floori(MapGenerator.MAP_WIDTH * 0.5)
	_spawn_room(map_data[MapGenerator.FLOORS-1][middle])

	# 2. ตั้งค่าการเลื่อนด้วยปุ่มลูกศร (ต้องทำหลังจาก Spawn ครบทุกห้องแล้ว)
	_setup_focus_neighbors()

	# จัดตำแหน่ง Visuals (โค้ดเดิม)
	var map_width_pixels := MapGenerator.X_DIST * (MapGenerator.MAP_WIDTH - 1)
	visuals.position.x = (get_viewport_rect().size.x - map_width_pixels) / 2
	visuals.position.y = get_viewport_rect().size.y * 0.9

func _setup_focus_neighbors() -> void:
	var all_rooms = rooms.get_children()
	
	for current_room in all_rooms:
		var r = current_room.room
		var closest_left: MapRoom = null
		var closest_right: MapRoom = null
		
		for target_room in all_rooms:
			var tr = target_room.room
			if tr.row == r.row:
				if tr.column < r.column:
					if closest_left == null or tr.column > closest_left.room.column:
						closest_left = target_room
				
				if tr.column > r.column:
					if closest_right == null or tr.column < closest_right.room.column:
						closest_right = target_room
		
		# แก้ไขตรงนี้: ถ้าไม่มีตัวเลือก ให้ใส่ get_path() ของตัวเองลงไป
		if closest_left:
			current_room.focus_neighbor_left = closest_left.get_path()
		else:
			current_room.focus_neighbor_left = current_room.get_path() # ล็อกไว้ที่ตัวเอง
			
		if closest_right:
			current_room.focus_neighbor_right = closest_right.get_path()
		else:
			current_room.focus_neighbor_right = current_room.get_path() # ล็อกไว้ที่ตัวเอง
			
		# บังคับ ขึ้น-ลง ไม่ให้ไปไหน (คุณทำไว้ดีแล้ว)
		current_room.focus_neighbor_top = current_room.get_path()
		current_room.focus_neighbor_bottom = current_room.get_path()

func _spawn_room(room: Room) -> void:
	var new_map_room := MAP_ROOM.instantiate() as MapRoom
	rooms.add_child(new_map_room)
	new_map_room.room = room
	new_map_room.selected.connect(_on_map_room_selected)
	_connect_lines(room)


func _connect_lines(room: Room) -> void:
	if room.next_rooms.is_empty():
		return
	var center_offset := Vector2(8, 8)
	for next: Room in room.next_rooms:
		var new_map_line := MAP_LINE.instantiate() as Line2D
		new_map_line.add_point(room.position + center_offset)
		new_map_line.add_point(next.position + center_offset)
		lines.add_child(new_map_line)

func unlock_floor(which_floor: int = floors_climbed) -> void:
	for map_room: MapRoom in rooms.get_children():
		if map_room.room.row == which_floor:
			map_room.available = true

func unlock_next_rooms() -> void:
	var first_unlocked := false
	for map_room: MapRoom in rooms.get_children():
		if last_room.next_rooms.has(map_room.room):
			map_room.available = true
			# โฟกัสไปที่ห้องแรกที่เลือกได้ทันที
			if not first_unlocked:
				map_room.grab_focus()
				first_unlocked = true

func show_map() -> void:
	show()
	camera_2d.enabled = true
	camera_2d.make_current()
	await get_tree().process_frame
	_focus_current_available_room()

func hide_map() -> void:
	hide()
	camera_2d.enabled = false
