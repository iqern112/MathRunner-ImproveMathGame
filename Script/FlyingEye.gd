extends CharacterBody2D
class_name FlyingEye

var attack_icon = preload("res://Resouce/ActionIcon/AttackIcon.tres")
var block_icon = preload("res://Resouce/ActionIcon/BlockIcon.tres")

@onready var mons_animad = $AnimatedSprite2D
@onready var mons_action_timer = $Timer
@onready var hint_icon = $Hint/NinePatchRect
@onready var hint_value = $Hint/NinePatchRect/Label
@onready var player = $"../Player"
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@export var max_hp: int = 20
@export var current_hp: int = 20
@export var shield: int = 0     # พลังป้องกัน/โล่
var attack_tween: Tween
var actions_value: int = 0
var original_position: Vector2
var mons_action


func _ready() -> void:
	# เริ่มต้นมาให้เล่น Appear ก่อนเลย
	mons_action_timer.timeout.connect(_on_mons_action_timer_timeout)
	original_position = global_position # บันทึกตำแหน่งยืนปกติไว้
	set_mons_status()
	mons_animad.play("Appear")
	GameEvents.control_to_monster.connect(action_combat_handle)
	GameEvents.combat_panel_open.connect(on_stop_timer)
	GameEvents.game_over_triggered.connect(player_die)

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	if GameEvents.is_combat:
		show_mons_time()
	# ลบ mons_animad.play("Idle") ออกจากตรงนี้!
	move_and_slide()

func move_to_player_and_attack():
	if not player: return
	var target_node = player.get_node("AttackPosition") 
	var target_pos = target_node.global_position
	if attack_tween:
		attack_tween.kill()
	attack_tween = create_tween()
	attack_tween.tween_property(self, "global_position", target_pos, 0.2).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	attack_tween.tween_callback(func():
		# เช็คอีกรอบว่าตายหรือยังก่อนจะเล่นอนิเมชั่นโจมตี
		if current_hp > 0:
			mons_animad.play("Attack")
	)

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
	elif mons_animad.animation == "Attack":
		GameEvents.monster_to_control.emit(mons_action, actions_value)
		var tween = create_tween()
		tween.tween_property(self, "global_position", original_position, 0.2).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
		mons_animad.play("Idle")
		#set_mons_status()
		prepare_mons_next_move()
	elif mons_animad.animation == "Defend":
		mons_animad.play("Idle")
		prepare_mons_next_move()
	elif mons_animad.animation == "Hurt":
		mons_animad.play("Idle")
		#prepare_mons_next_move()
	elif mons_animad.animation == "Death":
		$".".visible = false
		GameEvents.is_combat = false # ปิดโหมดต่อสู้
		GameEvents.monster_died.emit() # ส่ง Signal ใหม่ (คุณต้องไปเพิ่มใน GameEvents ด้วย)
		queue_free() # ลบมอนสเตอร์ทิ้งไปเลย
		

func prepare_mons_next_move():
	var actions = ["ATTACK", "BLOCK"]
	mons_action = actions[randi() % actions.size()]
	mons_action_timer.wait_time = randf_range(5.0, 10.0)
	actions_value = 0
	actions_value = randf_range(5, 10)
	mons_action_timer.start()
	if mons_action == "ATTACK":
		hint_icon.texture = attack_icon
		hint_value.text = str(actions_value)
		
	elif mons_action == "BLOCK":
		hint_icon.texture = block_icon
		hint_value.text = str(actions_value)

func _on_mons_action_timer_timeout():
	if mons_action == "ATTACK":
		#mons_animad.play("Attack1")
		#GameEvents.monster_to_control.emit(mons_action,actions_value)
		move_to_player_and_attack()
	elif mons_action == "BLOCK":
		mons_animad.play("Defend")
		shield += actions_value
	set_mons_status()
	#prepare_mons_next_move()


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
			if mons_animad.animation != "Attack":
				mons_animad.play("Hurt")
	else:
		current_hp -= final_damage
		if mons_animad.animation != "Attack":
			mons_animad.play("Hurt")
	
	set_mons_status()
	if current_hp <= 0: die()

func on_stop_timer(value):
	if value == "open":
		mons_action_timer.paused = true
	else :
		mons_action_timer.paused = false

func die():
	global_position = original_position
	mons_action_timer.stop() # ใช้ stop() จะแน่นอนกว่า paused ในบางกรณี
	if attack_tween:
		attack_tween.kill()
	$MonsterHp.visible = false
	$BuffDebuff.visible = false
	$Hint.visible = false
	mons_animad.play("Death")

func player_die(status):
	if status == "combat":
		$Timer.paused = true
		$MonsterHp.visible = false
		$BuffDebuff.visible = false
		$Hint.visible = false
		$MonsterShield.visible = false
