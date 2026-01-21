class_name MapGenerator # แก้ตัวสะกดจาก Ganeratoe
extends Node

const X_DIST := 30
const Y_DIST := 30
const PLACEMENT_RANDOMNESS := 0
const FLOORS := 15
const MAP_WIDTH := 7
const PATHS := 6

const MONSTER_ROOM_WEIGHT := 10.0
const SHOP_ROOM_WEIGHT := 2.5
const CAMPFIRE_ROOM_WEIGHT := 4.0
const EVENT_ROOM_WEIGHT := 5.0  # ปรับตัวเลขตามความเหมาะสม
const ELITE_ROOM_WEIGHT := 2.0

const MIN_ELITES := 2

var random_room_type_weights = {}

var random_room_type_total_weight := 0.0
var map_data: Array[Array]

#func _ready() -> void:
	#generate_map()

func generate_map() -> Array[Array]:
	map_data = _generate_initial_grid()
	var starting_points := _get_random_starting_points()
	for j in starting_points:
		var current_j := j
		for i in FLOORS - 1:
			current_j = _setup_connection(i, current_j)
	
	_setup_boss_room()
	_setup_random_room_weights()
	
	# ปรับส่วนนี้ให้วนลูปจนกว่าจะได้แผนที่ที่มี Elite ครบตามเงื่อนไข
	var elite_count := 0
	while elite_count < MIN_ELITES:
		_reset_room_types() # ล้างค่าประเภทห้องที่สุ่มไว้เดิม (ยกเว้นชั้นบังคับ)
		_setup_room_types()
		elite_count = _get_total_elite_count()
		
	return map_data

# ฟังก์ชันสำหรับรีเซ็ตประเภทห้องที่สุ่มมา เพื่อเริ่มสุ่มใหม่ถ้าเงื่อนไขไม่ผ่าน
func _reset_room_types() -> void:
	for current_floor in map_data:
		for room: Room in current_floor:
			# ปล่อยห้องที่ยังไม่ได้ระบุประเภทไว้ (NOT_ASSIGNED) เพื่อสุ่มใหม่
			# แต่ชั้นสุดท้าย (Boss) จะไม่โดนรีเซ็ตเพราะถูกเซ็ตไว้ใน _setup_boss_room
			if room.row != FLOORS - 1:
				room.type = Room.Type.NOT_ASSIGNED

# ฟังก์ชันนับจำนวน Elite ทั้งหมดในแผนที่
func _get_total_elite_count() -> int:
	var count := 0
	for current_floor in map_data:
		for room: Room in current_floor:
			if room.type == Room.Type.ELITE:
				count += 1
	return count

func _generate_initial_grid() -> Array[Array]:
	var result: Array[Array] = []
	
	for i in FLOORS:
		var adjacent_rooms: Array[Room] = []
		for j in MAP_WIDTH:
			var current_room := Room.new()
			
			# 1. ลดความสุ่มแกน Y ให้เหลือน้อยที่สุดเพื่อให้ชั้นดูเป็นระนาบเดียวกัน
			# 2. แกน X สุ่มได้เล็กน้อยเพื่อให้ดูไม่เป็นตารางหมากรุกเกินไป
			var offset := Vector2(
				randf_range(-1, 1) * PLACEMENT_RANDOMNESS, 
				randf_range(-0.2, 0.2) * PLACEMENT_RANDOMNESS # Y สุ่มน้อยมาก
			)
			
			# คำนวณตำแหน่งโดยอิงจากจุดกึ่งกลางของหน้าจอ (Optional)
			current_room.position = Vector2(j * X_DIST, i * -Y_DIST) + offset
			current_room.row = i
			current_room.column = j
			current_room.next_rooms = []
			
			adjacent_rooms.append(current_room)
		result.append(adjacent_rooms)
	return result

func _get_random_starting_points() -> Array[int]:
	var y_coordinates: Array[int] = [] # ในภาพคุณตั้งชื่อ y_coordinates แต่จริงๆ คือค่า Column (X)
	var unique_points: int = 0
	
	while unique_points < 2:
		unique_points = 0
		y_coordinates = []
		
		for i in range(PATHS):
			var starting_point := randi_range(0, MAP_WIDTH - 1)
			if not y_coordinates.has(starting_point):
				unique_points += 1
			y_coordinates.append(starting_point)
			
	return y_coordinates

func _setup_connection(i: int, j: int) -> int:
	var next_room: Room
	var current_room := map_data[i][j] as Room
	
	# วนลูปจนกว่าจะได้ห้องถัดไปที่ไม่ทำให้เส้นทางไขว้กัน
	while not next_room or _would_cross_existing_path(i, j, next_room):
		var random_j := clampi(randi_range(j - 1, j + 1), 0, MAP_WIDTH - 1)
		next_room = map_data[i + 1][random_j] as Room
	
	if not current_room.next_rooms.has(next_room):
		current_room.next_rooms.append(next_room)
		
	return next_room.column

func _would_cross_existing_path(i: int, j: int, room: Room) -> bool:
	var left_neighbour: Room
	var right_neighbour: Room
	
	if j > 0:
		left_neighbour = map_data[i][j - 1]
	if j < MAP_WIDTH - 1:
		right_neighbour = map_data[i][j + 1]
		
	# เช็คเพื่อนบ้านขวา: ถ้ามันเชื่อมไปทางซ้ายข้ามหัวเรา
	if right_neighbour and room.column > j:
		for next_room in right_neighbour.next_rooms:
			if next_room.column < room.column:
				return true
				
	# เช็คเพื่อนบ้านซ้าย: ถ้ามันเชื่อมไปทางขวาข้ามหัวเรา
	if left_neighbour and room.column < j:
		for next_room in left_neighbour.next_rooms:
			if next_room.column > room.column:
				return true
				
	return false

func _setup_boss_room() -> void:
	var middle := floori(MAP_WIDTH * 0.5)
	var boss_room := map_data[FLOORS - 1][middle] as Room
	
	# ทุกห้องในชั้นก่อนสุดท้ายที่มีทางไปต่อ ให้ชี้ไปที่บอสห้องเดียว
	for j in MAP_WIDTH:
		var current_room = map_data[FLOORS - 2][j] as Room
		if current_room.next_rooms:
			current_room.next_rooms = [] as Array[Room]
			current_room.next_rooms.append(boss_room)
			
	boss_room.type = Room.Type.BOSS

# อัปเดตในฟังก์ชัน _setup_random_room_weights
func _setup_random_room_weights() -> void:
	random_room_type_weights.clear()
	
	# 1. เริ่มที่ Monster
	var current_weight = MONSTER_ROOM_WEIGHT
	random_room_type_weights[Room.Type.MONSTER] = current_weight
	
	# 2. บวก Elite ต่อ
	current_weight += ELITE_ROOM_WEIGHT # อย่าลืมประกาศ const นี้ไว้ด้านบนด้วย
	random_room_type_weights[Room.Type.ELITE] = current_weight
	
	# 3. บวก Campfire
	current_weight += CAMPFIRE_ROOM_WEIGHT
	random_room_type_weights[Room.Type.CAMPFIRE] = current_weight
	
	# 4. บวก Shop
	current_weight += SHOP_ROOM_WEIGHT
	random_room_type_weights[Room.Type.SHOP] = current_weight
	
	# 5. บวก Event
	current_weight += EVENT_ROOM_WEIGHT # อย่าลืมประกาศ const นี้
	random_room_type_weights[Room.Type.EVENT] = current_weight
	
	# ตั้งค่า Total Weight เป็นค่าสุดท้ายที่บวกเสร็จ
	random_room_type_total_weight = current_weight

func _setup_room_types() -> void:
	# ชั้นแรกเป็น Monster เสมอ
	for room: Room in map_data[0]:
		if room.next_rooms.size() > 0:
			room.type = Room.Type.MONSTER
			
	# ชั้นที่ 9 เป็น Treasure เสมอ (FLOORS / 2)
	for room: Room in map_data[FLOORS / 2]:
		if room.next_rooms.size() > 0:
			room.type = Room.Type.TREASURE
			
	# ชั้นก่อนบอสเป็น Campfire เสมอ (FLOORS - 2)
	for room: Room in map_data[FLOORS - 2]:
		if room.next_rooms.size() > 0:
			room.type = Room.Type.CAMPFIRE
			
	# ส่วนสุดท้าย: สุ่มประเภทให้กับห้องที่เหลือทั้งหมดที่ยังไม่ได้กำหนด (NOT_ASSIGNED)
	for current_floor in map_data:
		for room: Room in current_floor:
			for next_room: Room in room.next_rooms:
				if next_room.type == Room.Type.NOT_ASSIGNED:
					_set_room_randomly(next_room)

func _set_room_randomly(room_to_set: Room) -> void:
	var campfire_below_4 := true
	var consecutive_campfire := true
	var consecutive_shop := true
	var campfire_on_13 := true
	# เพิ่มเงื่อนไขใหม่
	var elite_below_6 := true 

	var type_candidate: Room.Type
	
	while campfire_below_4 or consecutive_campfire or consecutive_shop or campfire_on_13 or elite_below_6:
		type_candidate = _get_random_room_type_by_weight()
		
		var is_campfire := type_candidate == Room.Type.CAMPFIRE
		var is_shop := type_candidate == Room.Type.SHOP
		var is_elite := type_candidate == Room.Type.ELITE
		
		campfire_below_4 = is_campfire and room_to_set.row < 3
		consecutive_campfire = is_campfire and _room_has_parent_of_type(room_to_set, Room.Type.CAMPFIRE)
		consecutive_shop = is_shop and _room_has_parent_of_type(room_to_set, Room.Type.SHOP)
		campfire_on_13 = is_campfire and room_to_set.row == 12
		# กฎ: Elite จะไม่เกิดใน 5 ชั้นแรก
		elite_below_6 = is_elite and room_to_set.row < 5 
		
	room_to_set.type = type_candidate

# ฟังก์ชันสุ่มประเภทห้องตามน้ำหนักสะสม (image_3048ea.png)
func _get_random_room_type_by_weight() -> Room.Type:
	var roll := randf_range(0.0, random_room_type_total_weight) # สุ่มเลขในช่วงน้ำหนักรวม
	
	for type: Room.Type in random_room_type_weights:
		# หากค่าน้ำหนักสะสมมากกว่าเลขที่สุ่มได้ ให้คืนค่าประเภทนั้น
		if random_room_type_weights[type] > roll:
			return type
			
	return Room.Type.MONSTER # ค่าเริ่มต้นหากไม่ตรงเงื่อนไขใดเลย

# ฟังก์ชันตรวจสอบว่าห้องก่อนหน้า (Parent) มีประเภทที่ระบุหรือไม่ (image_3045a4.jpg)
func _room_has_parent_of_type(room: Room, type: Room.Type) -> bool:
	var parents: Array[Room] = [] # เก็บรายชื่อห้องที่เป็นทางผ่านมายังห้องปัจจุบัน
	
	# ตรวจสอบห้องฝั่งซ้ายบน
	if room.column > 0 and room.row > 0:
		var parent_candidate := map_data[room.row - 1][room.column - 1] as Room
		if parent_candidate.next_rooms.has(room):
			parents.append(parent_candidate)
			
	# ตรวจสอบห้องตรงหัวด้านบน
	if room.row > 0:
		var parent_candidate := map_data[room.row - 1][room.column] as Room
		if parent_candidate.next_rooms.has(room):
			parents.append(parent_candidate)
			
	# ตรวจสอบห้องฝั่งขวาบน
	if room.column < MAP_WIDTH - 1 and room.row > 0:
		var parent_candidate := map_data[room.row - 1][room.column + 1] as Room
		if parent_candidate.next_rooms.has(room):
			parents.append(parent_candidate)
			
	# ตรวจสอบว่ามีห้อง Parent ห้องใดที่มีประเภทตรงกับที่กำหนดหรือไม่
	for parent: Room in parents:
		if parent.type == type:
			return true # คืนค่า true ทันทีที่เจอ
			
	return false # หากตรวจสอบครบแล้วไม่เจอ ให้คืนค่า false
