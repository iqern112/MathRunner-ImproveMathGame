extends CharacterBody2D
const SPEED = 150.0  # ความเร็วในการเดิน
const JUMP_VELOCITY = -300.0 # ความสูงในการกระโดด (ค่าติดลบคือขึ้นบน)

@onready var PlayerAni = $AnimatedSprite2D

var is_dashing = false
var is_die = false

# ดึงค่าแรงโน้มถ่วงจาก Project Settings มาใช้
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready() -> void:
	GameEvents.correct_answer_signal.connect(dash)
	GameEvents.game_over_triggered.connect(die)

func _physics_process(delta):
	# 1. ใส่แรงโน้มถ่วง (ถ้าไม่ได้อยู่บนพื้น ให้ตัวละครตกลงมา)
	if not is_on_floor():
		velocity.y += gravity * delta
	if is_die:
		velocity = Vector2.ZERO
	elif is_dashing:pass 
	else:
		# สถานะปกติ: เดินไปข้างหน้า
		velocity.x = SPEED
		
		# เล่นอนิเมชั่นตามสถานะพื้นดิน
		if is_on_floor():
			PlayerAni.play("Walk")
	print("Player:",SPEED)
	move_and_slide()

func dash():
	if is_dashing: return
	is_dashing = true
	
	# สุ่มท่าทาง
	var actions = ["Dash", "Slide"]
	var selected_action = actions.pick_random()
	
	PlayerAni.play(selected_action)
	
	# ตั้งความเร็วพุ่ง
	velocity.x = SPEED * 2

func die():
	await get_tree().create_timer(0.6).timeout
	is_die = true
	 
	PlayerAni.play("Die")

func _on_animated_sprite_2d_animation_finished():
	# คืนค่าสถานะเพื่อให้กลับไปวิ่งปกติเมื่อจบท่าพิเศษ
	if PlayerAni.animation == "Dash" or PlayerAni.animation == "Slide":
		is_dashing = false
