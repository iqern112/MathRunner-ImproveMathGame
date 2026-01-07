extends CharacterBody2D

@export var speed = 200.0         # ความเร็วปัจจุบัน
@export var min_speed = 200.0      # ความเร็วขั้นต่ำ (ไม่ให้ตัวละครหยุดนิ่งสนิท)
@export var friction = 2.0        # ค่าแรงเสียดทาน (ยิ่งมากยิ่งลดเร็ว)
var acceleration = 40.00

func _physics_process(delta):
	# --- ส่วนที่เพิ่มเข้ามา: ค่อยๆ ลดความเร็วตามเวลา ---
	if speed > min_speed:
		# ลดค่า speed ลงตามเวลา (delta) คูณกับ friction
		speed -= friction * delta
		
		# ป้องกันไม่ให้ speed ต่ำกว่าค่าที่กำหนด
		if speed < min_speed:
			speed = min_speed
	# ------------------------------------------

	# กำหนดความเร็วแกน X
	velocity.x = speed
	print("player:")
	print(speed)
	move_and_slide()

# เพิ่มฟังก์ชันนี้ใน Main.gd หรือ CharacterBody2D.gd
func shake_screen():
	var camera = $Camera2D
	var tween = create_tween()
	for i in range(4):
		var rand_offset = Vector2(randf_range(-7, 7), randf_range(-7, 7))
		tween.tween_property(camera, "offset", rand_offset, 0.03)
	tween.tween_property(camera, "offset", Vector2.ZERO, 0.03)

func dash():
	var original_speed = speed
	var dash_boost = 500.0 # ความเร็วที่เพิ่มขึ้นชั่วคราว
	
	var tween = create_tween()
	# พุ่งไปข้างหน้าอย่างเร็ว
	tween.tween_property(self, "speed", original_speed + dash_boost, 0.1).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	# ค่อยๆ กลับสู่ความเร็วปกติ (ที่บวกค่าเร่งจากการตอบถูกแล้ว)
	tween.tween_property(self, "speed", original_speed + acceleration, 0.4).set_trans(Tween.TRANS_SINE)
	
	# 3. เอฟเฟกต์ตัวยืด (Squash & Stretch)
	var scale_tween = create_tween()
	scale_tween.tween_property($CollisionShape2D/Sprite2D, "scale", Vector2(1.4, 0.7), 0.1) # ตัวแบนและยาว
	scale_tween.tween_property($CollisionShape2D/Sprite2D, "scale", Vector2(1.0, 1.0), 0.2) # กลับสู่ปกติ

func on_answer_correct():
	speed += acceleration # วิ่งเร็วขึ้นเพื่อทิ้งห่าง
	
func on_answer_wrong():
	# เมื่อตอบผิด อาจจะลดความเร็วลงทันที หรือจะให้หยุดชะงักก็ได้
	speed -= acceleration 
	if speed < min_speed:
		speed = min_speed
