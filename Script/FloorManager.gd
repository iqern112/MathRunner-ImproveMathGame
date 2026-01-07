extends Node2D

@export var chunk_width: float = 384.0  # ความกว้างพิกเซลของแต่ละแผ่น
var chunks: Array = []

func _ready():
	# เก็บแผ่นพื้นทั้ง 3 แผ่นเข้า Array
	chunks = get_children()
	# จัดเรียงลำดับตามตำแหน่ง X เพื่อความชัวร์
	chunks.sort_custom(func(a, b): return a.global_position.x < b.global_position.x)

func _process(_delta):
	# 1. หาตำแหน่งขอบซ้ายของจอจากกล้อง
	var camera = get_viewport().get_camera_2d()
	if not camera: return
	
	var view_width = get_viewport_rect().size.x
	var camera_left_edge = camera.get_screen_center_position().x - (view_width / 2)

	# 2. เช็คแผ่นที่อยู่ "ซ้ายสุด" (ตัวแรกใน Array)
	var first_chunk = chunks[0]
	
	# ถ้าขอบขวาของแผ่นแรก หลุดขอบซ้ายของจอไปแล้ว
	if first_chunk.global_position.x + chunk_width < camera_left_edge:
		# 3. ย้ายแผ่นแรกไปต่อท้ายแผ่นสุดท้าย
		var last_chunk = chunks[chunks.size() - 1]
		first_chunk.global_position.x = last_chunk.global_position.x + chunk_width
		
		# 4. อัปเดตลำดับใน Array (ย้ายตัวแรกไปเป็นตัวสุดท้าย)
		chunks.pop_front()
		chunks.push_back(first_chunk)
