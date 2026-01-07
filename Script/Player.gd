extends CharacterBody2D
const SPEED = 150.0  # ความเร็วในการเดิน
const JUMP_VELOCITY = -300.0 # ความสูงในการกระโดด (ค่าติดลบคือขึ้นบน)

@onready var PlayerAni = $AnimatedSprite2D

# ดึงค่าแรงโน้มถ่วงจาก Project Settings มาใช้
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _physics_process(delta):
	# 1. ใส่แรงโน้มถ่วง (ถ้าไม่ได้อยู่บนพื้น ให้ตัวละครตกลงมา)
	if not is_on_floor():
		velocity.y += gravity * delta

	# 2. การกระโดด (ถ้ากดปุ่ม UI Accept เช่น Spacebar และอยู่บนพื้น)
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# 3. รับ Input ซ้าย-ขวา (A, D หรือ ลูกศร)
	var direction = Input.get_axis("ui_left", "ui_right")
	
	if direction:
		velocity.x = direction * SPEED
		PlayerAni.play("walk")
		PlayerAni.flip_h = direction < 0
	else:
		# ถ้าไม่กดปุ่ม ให้ค่อยๆ หยุดเดิน
		velocity.x = move_toward(velocity.x, 0, SPEED)
		PlayerAni.play("Idle")
	# 4. ฟังก์ชันสำคัญที่ทำให้การเคลื่อนที่และการชนทำงาน
	move_and_slide()

func dash():
	var original_speed = SPEED
	var dash_boost = 500.0 # ความเร็วที่เพิ่มขึ้นชั่วคราว
	
