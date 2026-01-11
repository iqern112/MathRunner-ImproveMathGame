extends CharacterBody2D

var attack_icon = preload("res://Resouce/ActionIcon/AttackIcon.tres")
var block_icon = preload("res://Resouce/ActionIcon/BlockIcon.tres")

@onready var mons_animad = $AnimatedSprite2D
@onready var mons_action_timer = $Timer
@onready var hint_icon = $Hint/NinePatchRect
@onready var hint_value = $Hint/NinePatchRect/Label

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@export var max_hp: int = 30
@export var current_hp: int = 30
@export var shield: int = 0     # พลังป้องกัน/โล่
@export var attack_power: int = 5 # พลังโจมตี

var mons_action


func _ready() -> void:
	# เริ่มต้นมาให้เล่น Appear ก่อนเลย
	mons_action_timer.timeout.connect(_on_mons_action_timer_timeout)
	set_mons_status()
	mons_animad.play("Appear")
	GameEvents.control_to_monster.connect(action_combat_handle)
	GameEvents.combat_panel_open.connect(on_stop_timer)

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	if GameEvents.is_combat:
		show_mons_time()
	# ลบ mons_animad.play("Idle") ออกจากตรงนี้!
	move_and_slide()

func show_mons_time():
	$Hint/time.text = " %.1d" % mons_action_timer.time_left

func set_mons_status():
	$MonsterHp.max_value = max_hp
	$MonsterHp.value = current_hp
	$MonsterHp/MonsterHpLabel.text = str(current_hp) + "/" + str(max_hp)
	if shield > 0:
		$MonsterShield.visible = true
		$MonsterShield/MonsterShieldLabel.text = str(shield)
	else :
		$MonsterShield.visible = false

# เชื่อมต่อ Signal จาก AnimatedSprite2D (ไปที่ Node -> Signals -> animation_finished)
func _on_animated_sprite_2d_animation_finished():
	if mons_animad.animation == "Appear":
		mons_animad.play("Idle")
		$MonsterHp.visible = true
		$BuffDebuff.visible = true
		$Hint.visible = true
		prepare_mons_next_move()
	elif mons_animad.animation == "Death":
		$".".visible = false

func prepare_mons_next_move():
	var actions = ["ATTACK", "BLOCK"]
	mons_action = actions[randi() % actions.size()]
	mons_action_timer.wait_time = randf_range(5.0, 10.0)
	mons_action_timer.start()
	if mons_action == "ATTACK":
		hint_icon.texture = attack_icon
		hint_value.text = str(5)
	elif mons_action == "BLOCK":
		hint_icon.texture = block_icon
		hint_value.text = str(5)

func _on_mons_action_timer_timeout():
	if mons_action == "ATTACK":
		GameEvents.monster_to_control.emit(mons_action,5)
	elif mons_action == "BLOCK":
		shield += 5
	set_mons_status()
	prepare_mons_next_move()


func action_combat_handle(action,value):
	if action == "Attack":
		take_damage(value)
	elif action == "Drill":
		current_hp -= value
	set_mons_status()

func take_damage(final_damage: int):
	
	if shield > 0:
		if shield >= final_damage:
			shield -= final_damage
		else:
			var remaining_dmg = final_damage - shield
			shield = 0
			current_hp -= remaining_dmg
			
	else:
		current_hp -= final_damage
	
	set_mons_status()
	if current_hp <= 0: die()

func on_stop_timer(value):
	if value == "open":
		mons_action_timer.paused = true
	else :
		mons_action_timer.paused = false

func die():
	$MonsterHp.visible = false
	$BuffDebuff.visible = false
	$Hint.visible = false
	$Timer.paused = true
	mons_animad.play("Death")
	
	
