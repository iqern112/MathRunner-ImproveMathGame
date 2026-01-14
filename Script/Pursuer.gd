# Pursuer.gd
extends CharacterBody2D

const SPEED = 150.0 #150 
const KILL_DISTANCE = 60.0 
const DASH_KILL = 120.0


@onready var pursuer_animad = $pursuer_animad
@onready var player = $"../Player" 
@onready var pursuer = $"."

var is_falling = false
var is_attacking = false # เพิ่มสถานะการโจมตี
var is_dashing = false
var is_die = false
var is_figth_monster = false
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var random_event_timer : Timer
var is_slowed = false

func _ready() -> void:
	GameEvents.wrong_answer_signal.connect(_on_answer_wrong)
	GameEvents.spawn_monster.connect(hide_pursuer)
	GameEvents.monster_died.connect(_on_combat_finished)
	create_timer()

func create_timer():
	random_event_timer = Timer.new()
	add_child(random_event_timer)
	random_event_timer.timeout.connect(_on_random_event_timeout)
	start_random_timer()

func _on_answer_wrong():
	var distance = global_position.distance_to(player.global_position)
	
	if is_figth_monster:
		return
	elif distance <= KILL_DISTANCE:
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
	#velocity = Vector2.ZERO # หยุดเดิน
	pursuer_animad.play("Attack") # สมมติว่าชื่ออนิเมชั่นข่วนคือ Attack
	GameEvents.game_over_triggered.emit("pursuer")

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	if is_figth_monster:
		velocity.x = 0
	elif is_die:
		if is_on_floor():
			pursuer_animad.play("Idle")
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
			pursuer_animad.play("Run")
	move_and_slide()

#func _physics_process(delta):
	#if not is_on_floor():
		#velocity.y += gravity * delta
	#
	#if is_figth_monster:
		#velocity.x = 0
	#elif is_slowed:
		#velocity.x = SPEED * 0.3 # วิ่งช้าลงมาก
		#pursuer_animad.play("Run") # หรือเล่นอนิเมชั่นเหนื่อย
	#elif is_falling:
		#velocity.x = SPEED * 0.5
	#else:
		#velocity.x = SPEED * 1.1 # ให้วิ่งเร็วกว่า Player นิดหน่อยเสมอเพื่อกดดัน
		#if is_on_floor():
			#pursuer_animad.play("Run")
	#move_and_slide()

func _on_combat_finished():
	is_figth_monster = false # ปลดล็อคให้วิ่งได้
	start_random_timer() # เริ่มนับเวลาสุ่มเหตุการณ์ใหม่
	global_position.x = player.global_position.x - 80 # วาร์ปไปข้างหลังผู้เล่นเล็กน้อย
	global_position.y = player.global_position.y - 100 # วาร์ปขึ้นข้างบน
	fall()

func dash():
	if is_falling or is_attacking or is_dashing: return
	is_dashing = true
	pursuer_animad.play("Dash") # มั่นใจว่าชื่อ Animation ใน SpriteFrames ตรงกัน
	
	# ปรับความเร็วให้พุ่งแรงกว่าผู้เล่นเพื่อความตื่นเต้น
	velocity.x = SPEED * 2
	
	# ใช้ Timer เพื่อกำหนดระยะเวลาการพุ่ง (แทน Tween)
	await get_tree().create_timer(0.3).timeout 
	is_dashing = false

func fall():
	if is_falling or is_attacking or is_dashing: return
	is_falling = true
	pursuer_animad.play("Fall")
	velocity.y = 100 

func start_random_timer():
	if is_figth_monster:
		return
	#var random_time = randf_range(5.0, 15.0)
	var random_time = 5.0
	random_event_timer.start(random_time)

func _on_random_event_timeout():
	# ถ้าตายอยู่ หรือกำลังโจมตี/ตก/แดช ให้รอรอบหน้า
	if is_die or is_attacking or is_falling or is_dashing:
		start_random_timer()
		return

	var distance = global_position.distance_to(player.global_position)
	if is_figth_monster:
		pass
	elif distance <= KILL_DISTANCE:
		attack_and_game_over()
	elif distance <= DASH_KILL:
		dash()
	else:
		global_position.x = player.global_position.x - 80 # วาร์ปไปข้างหลังผู้เล่นเล็กน้อย
		global_position.y = player.global_position.y - 100 # วาร์ปขึ้นข้างบน
		fall()

	start_random_timer()

func hide_pursuer():
	is_figth_monster = true
	velocity.x = 0
	var hide_pos = player.global_position + Vector2(-200, -15)
	pursuer.global_position = hide_pos


func _on_pursuer_animad_animation_finished() -> void:
	if pursuer_animad.animation == "Fall":
		is_falling = false
	if pursuer_animad.animation == "Dash":
		is_dashing = false
	if pursuer_animad.animation == "Attack":
		is_attacking = false
		is_die = true
		#GameEvents.game_over_triggered.emit("pursuer")
		#get_tree().paused = true 
		#$"../CanvasLayer/GameOver".visible = true
