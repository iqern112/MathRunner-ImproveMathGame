extends CharacterBody2D
const SPEED = 150.0  # ความเร็วในการเดิน
const JUMP_VELOCITY = -300.0 # ความสูงในการกระโดด (ค่าติดลบคือขึ้นบน)

@onready var PlayerAni = $PlayerAnimad

var is_dashing = false
var is_die = false
var is_fight = false
var is_not_ready = true

@export var max_hp: int = 20
@export var current_hp: int = 20
@export var shield: int = 0     # พลังป้องกัน/โล่


var incress_damage: int = 0
var add_block: int = 0
var reduce_damage: int = 0

# ดึงค่าแรงโน้มถ่วงจาก Project Settings มาใช้
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready() -> void:
	if is_not_ready:
		$Camera2D.enabled = false
	GameEvents.correct_answer_signal.connect(dash)
	GameEvents.game_over_triggered.connect(die)
	GameEvents.spawn_monster.connect(set_fight)
	GameEvents.control_to_player.connect(combat_action_handle)
	GameEvents.route_changed.connect(_on_monster_died)
	GameEvents.into_out_cut.connect(player_fade_out)
	set_player_status()


func _physics_process(delta):
	if is_not_ready:
		pass
	elif is_die:
		velocity.x = 0
	elif not is_on_floor():
		velocity.y += gravity * delta
	elif GameEvents.is_combat:
		velocity.x = 0
		if PlayerAni.animation != "Hurt":
			PlayerAni.play("Idle")
	elif is_dashing:
		pass 
	else:
		velocity.x = SPEED
		if is_on_floor():
			PlayerAni.play("Walk")
	
	move_and_slide()

func player_fade_out():
	$AnimationPlayer.play("fade_out_cut")

func set_player_status():
	$PlayerHp.max_value = max_hp
	$PlayerHp.value = current_hp
	$PlayerHp/PlayerHpLabel.text = str(current_hp) + "/" + str(max_hp)
	if shield > 0:
		$PlayerShield.visible = true
		$PlayerShield/PlayerHpLabel.text = str(shield)
	else :
		$PlayerShield.visible = false
	if current_hp <= 0:
		velocity.x = 0
		GameEvents.game_over_triggered.emit()

func dash():
	if is_dashing or is_die or is_fight: return # ไม่ Dash ถ้ากำลังสู้หรือตาย
	is_dashing = true
	
	# สุ่มท่าทาง
	var actions = ["Dash", "Slide"]
	var selected_action = actions.pick_random()
	PlayerAni.play(selected_action)
	
	# ใช้ Tween เพื่อควบคุมความเร็วให้คงที่ในช่วงเวลาหนึ่ง
	var dash_tween = create_tween()
	# พุ่งด้วยความเร็ว SPEED * 2 เป็นเวลา 0.4 วินาที
	dash_tween.tween_method(func(v): velocity.x = v, SPEED * 2.5, SPEED, 1.54).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	
	# เมื่อจบ Tween ให้คืนค่าสถานะ
	dash_tween.finished.connect(func():
		is_dashing = false
		if not is_fight and not is_die:
			velocity.x = SPEED # กลับมาวิ่งความเร็วปกติ
	)

func die():
	PlayerAni.play("Die")
	is_die = true


func _on_monster_died():
	is_fight = false
	is_dashing = false

func _on_animated_sprite_2d_animation_finished():
	# คืนค่าสถานะเพื่อให้กลับไปวิ่งปกติเมื่อจบท่าพิเศษ
	if PlayerAni.animation == "Dash" or PlayerAni.animation == "Slide":
		is_dashing = false

func set_fight():
	is_fight = true


# ฟังก์ชันรับดาเมจ (เอาไว้ให้ Monster เรียกใช้)
func take_damage(final_damage: int):
	# ลดดาเมจตามสกิล armor
	#var final_damage = max(1, amount - GameEvents.damage_reduction)
	if shield > 0:
		if shield >= final_damage:
			shield -= final_damage
		else:
			var remaining_dmg = final_damage - shield
			shield = 0
			current_hp -= remaining_dmg
			PlayerAni.play("Hurt")
	else:
		current_hp -= final_damage
		PlayerAni.play("Hurt")
	
	set_player_status()
	if current_hp <= 0: die()

func combat_action_handle(action,value):
	if action == "Block":
		shield += value
	elif action == "ATTACK":
		take_damage(value)
	elif action == "potion":
		current_hp += value
	set_player_status()

func activate_player_camera():
	is_not_ready = false # ปลดล็อกการประมวลผลฟิสิกส์ให้เริ่มวิ่ง
	$Camera2D.enabled = true
	$Camera2D.make_current()

func _on_player_animad_animation_finished() -> void:
	if PlayerAni.animation == "Dash" or PlayerAni.animation == "Slide":
		is_dashing = false
	elif PlayerAni.animation == "Die":
		pass
	elif PlayerAni.animation == "Hurt":
		if current_hp > 0:
			if is_fight:
				PlayerAni.play("Idle")
			else:
				PlayerAni.play("Walk")



func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "cam_fade":
		$AnimationPlayer.play("fade_out_cut")
	elif anim_name == "fade_out_cut":
		GameEvents.fade_out_cut.emit()
		is_not_ready = false
