# Pursuer.gd
extends CharacterBody2D

const SPEED = 150.0  
const KILL_DISTANCE = 60.0 
const DASH_KILL = 120.0


@onready var PlayerAni = $AnimatedSprite2D
@onready var player = $"../Player" 

var is_falling = false
var is_attacking = false # เพิ่มสถานะการโจมตี
var is_dashing = false
var is_die = false
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var random_event_timer : Timer

func _ready() -> void:
	GameEvents.wrong_answer_signal.connect(_on_answer_wrong)
	
	# สร้าง Timer สำหรับเหตุการณ์สุ่ม
	random_event_timer = Timer.new()
	add_child(random_event_timer)
	random_event_timer.timeout.connect(_on_random_event_timeout)
	start_random_timer()

func _on_answer_wrong():
	var distance = global_position.distance_to(player.global_position)
	
	if distance <= KILL_DISTANCE:
		attack_and_game_over()
		
	elif distance <= DASH_KILL:
		# แทนที่จะใช้ Tween ให้สั่ง dash แบบเดียวกับผู้เล่น
		dash() 
	else:
		global_position.x = player.global_position.x - 80 
		global_position.y = player.global_position.y - 100
		fall()

func attack_and_game_over():
	if is_falling or is_attacking or is_dashing: return
	is_attacking = true
	is_falling = false # หยุดสถานะอื่น
	GameEvents.game_over_triggered.emit()
	#velocity = Vector2.ZERO # หยุดเดิน
	PlayerAni.play("Attack") # สมมติว่าชื่ออนิเมชั่นข่วนคือ Attack
	
	# รอให้อนิเมชั่นข่วนเล่นจบก่อนค่อยเปลี่ยนฉากหรือขึ้นหน้า Game Over
	# หรือจะใช้ await PlayerAni.animation_finished ก็ได้

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	if is_die:
		if is_on_floor():
			PlayerAni.play("Idle")
	elif is_attacking:pass 
		#velocity.x = 0
	elif is_dashing:pass
		# ในขณะ Dash เรากำหนด velocity.x ให้สูงมาก
		# และไม่ต้องเช็ค is_on_floor เพื่อไม่ให้เล่น Run ทับ
	elif is_falling:
		velocity.x = SPEED * 0.5 
	else:
		velocity.x = SPEED
		if is_on_floor():
			PlayerAni.play("Run")
	
	move_and_slide()

func dash():
	if is_falling or is_attacking or is_dashing: return
	is_dashing = true
	PlayerAni.play("Dash") # มั่นใจว่าชื่อ Animation ใน SpriteFrames ตรงกัน
	
	# ปรับความเร็วให้พุ่งแรงกว่าผู้เล่นเพื่อความตื่นเต้น
	velocity.x = SPEED * 2
	
	# ใช้ Timer เพื่อกำหนดระยะเวลาการพุ่ง (แทน Tween)
	await get_tree().create_timer(0.3).timeout 
	is_dashing = false

func fall():
	if is_falling or is_attacking or is_dashing: return
	is_falling = true
	PlayerAni.play("Fall")
	velocity.y = 100 

func _on_animated_sprite_2d_animation_finished():
	if PlayerAni.animation == "Fall":
		is_falling = false
	if PlayerAni.animation == "Dash":
		is_dashing = false
	if PlayerAni.animation == "Attack":
		is_attacking = false # เพิ่มสถานะการโจมตี
		is_die = true
		#get_tree().paused = true 
		#$"../CanvasLayer/GameOver".visible = true

func start_random_timer():
	#var random_time = randf_range(5.0, 15.0)
	var random_time = 5.0
	random_event_timer.start(random_time)

func _on_random_event_timeout():
	# ถ้าตายอยู่ หรือกำลังโจมตี/ตก/แดช ให้รอรอบหน้า
	if is_die or is_attacking or is_falling or is_dashing:
		start_random_timer()
		return

	var distance = global_position.distance_to(player.global_position)
	print("dis:",distance)
	if distance <= KILL_DISTANCE:
		attack_and_game_over()
	elif distance <= DASH_KILL:
		dash()
	else:
		global_position.x = player.global_position.x - 80 # วาร์ปไปข้างหลังผู้เล่นเล็กน้อย
		global_position.y = player.global_position.y - 100 # วาร์ปขึ้นข้างบน
		fall()

	start_random_timer()
