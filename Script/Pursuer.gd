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
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var random_event_timer : Timer
var is_slowed = false

func _ready() -> void:
	GameEvents.wrong_answer_signal.connect(_on_answer_wrong)
	GameEvents.spawn_monster.connect(hide_pursuer)
	GameEvents.campfire_opened.connect(hide_pursuer)
	GameEvents.shop_opened.connect(hide_pursuer)
	GameEvents.event_opened.connect(hide_pursuer)
	GameEvents.treasure_opened.connect(hide_pursuer)
	GameEvents.route_changed.connect(_on_combat_finished)
	GameEvents.game_over_triggered.connect(game_over)
	GameEvents.cam_fade_in.connect(set_start)

func set_start():
	show()
	create_timer()
	fall()

func create_timer():
	random_event_timer = Timer.new()
	add_child(random_event_timer)
	random_event_timer.timeout.connect(_on_random_event_timeout)
	start_random_timer()

func _on_answer_wrong():
	var distance = global_position.distance_to(player.global_position)
	
	if GameEvents.is_stop:
		return
	elif distance <= KILL_DISTANCE:
		attack_player()
	elif distance <= DASH_KILL:
		# แทนที่จะใช้ Tween ให้สั่ง dash แบบเดียวกับผู้เล่น
		dash() 
	else:
		fall()

func attack_player():
	if is_falling or is_attacking or is_dashing: return
	is_attacking = true
	pursuer_animad.play("Attack") 

func game_over():
	is_die = true
	velocity = Vector2.ZERO

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	if GameEvents.is_stop:
		velocity.x = 0
	elif is_die:
		if is_on_floor():
			pursuer_animad.play("Idle")
	elif is_attacking:pass 
	elif is_dashing:pass
	elif is_falling:
		velocity.x = SPEED * 0.5 
	else:
		velocity.x = SPEED
		if is_on_floor():
			pursuer_animad.play("Run")
	move_and_slide()

func _on_combat_finished(name):
	start_random_timer() # เริ่มนับเวลาสุ่มเหตุการณ์ใหม่
	fall()

func dash():
	if is_falling or is_attacking or is_dashing: return
	is_dashing = true
	pursuer_animad.play("Dash")
	velocity.x = SPEED * 2
	await get_tree().create_timer(0.3).timeout 
	is_dashing = false

func fall():
	global_position.x = player.global_position.x - 80 
	global_position.y = player.global_position.y - 100
	if is_falling or is_attacking or is_dashing: return
	is_falling = true
	pursuer_animad.play("Fall")
	velocity.y = 100 

func start_random_timer():
	if GameEvents.is_stop:
		return
	#var random_time = randf_range(5.0, 15.0)
	var random_time = 5.0
	random_event_timer.start(random_time)

func _on_random_event_timeout():
	if is_die or is_attacking or is_falling or is_dashing:
		start_random_timer()
		return

	var distance = global_position.distance_to(player.global_position)
	if GameEvents.is_stop:
		pass
	elif distance <= KILL_DISTANCE:
		attack_player()
	elif distance <= DASH_KILL:
		dash()
	else:
		fall()

	start_random_timer()

func hide_pursuer():
	velocity.x = 0
	var hide_pos = player.global_position + Vector2(-200, -15)
	pursuer.global_position = hide_pos


func _on_pursuer_animad_animation_finished() -> void:
	if pursuer_animad.animation == "Fall":
		is_falling = false
	if pursuer_animad.animation == "Dash":
		is_dashing = false
	if pursuer_animad.animation == "Attack":
		GameEvents.monster_to_control.emit("ATTACK", 5) 
		is_attacking = false
		
