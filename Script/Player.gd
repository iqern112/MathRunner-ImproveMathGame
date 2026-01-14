extends CharacterBody2D
const SPEED = 150.0  # ความเร็วในการเดิน
const JUMP_VELOCITY = -300.0 # ความสูงในการกระโดด (ค่าติดลบคือขึ้นบน)

@onready var PlayerAni = $PlayerAnimad

var is_dashing = false
var is_die = false
var is_fight = false

@export var max_hp: int = 20
@export var current_hp: int = 20
@export var shield: int = 0     # พลังป้องกัน/โล่


var incress_damage: int = 0
var add_block: int = 0
var reduce_damage: int = 0

# ดึงค่าแรงโน้มถ่วงจาก Project Settings มาใช้
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready() -> void:
	GameEvents.correct_answer_signal.connect(dash)
	GameEvents.game_over_triggered.connect(die)
	GameEvents.spawn_monster.connect(set_fight)
	GameEvents.control_to_player.connect(combat_action_handle)
	GameEvents.monster_died.connect(_on_monster_died)
	mark()
	set_player_status()

func mark():
	await get_tree().create_timer(3).timeout 
	GameEvents.add_money(1000)

func _physics_process(delta):
	if is_die:
		pass
	elif not is_on_floor():
		velocity.y += gravity * delta
	elif is_fight:
		velocity.x = 0
		if PlayerAni.animation != "Hurt":
			PlayerAni.play("Idle")
	elif is_dashing:pass 
	else:
		velocity.x = SPEED
		if is_on_floor():
			PlayerAni.play("Walk")
	
	move_and_slide()

func set_player_status():
	$PlayerHp.max_value = max_hp
	$PlayerHp.value = current_hp
	$PlayerHp/PlayerHpLabel.text = str(current_hp) + "/" + str(max_hp)
	if shield > 0:
		$PlayerShield.visible = true
		$PlayerShield/PlayerHpLabel.text = str(shield)
	else :
		$PlayerShield.visible = false
	if current_hp <= 0: GameEvents.game_over_triggered.emit("combat")

func dash():
	if is_dashing: return
	is_dashing = true
	var actions = ["Dash", "Slide"]
	var selected_action = actions.pick_random()
	PlayerAni.play(selected_action)
	velocity.x = SPEED * 2

func die(status):
	if status == "pursuer":
		await get_tree().create_timer(0.6).timeout
		velocity.x = 0
		PlayerAni.play("Die")
		is_die = true
	if status == "combat":
		PlayerAni.play("Die")
		is_die = true


func _on_monster_died():
	is_fight = false        # ปลดล็อคตัวแปรในตัว Player
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
	if current_hp <= 0: die("combat")

func combat_action_handle(action,value):
	if action == "Block":
		shield += value
	elif action == "ATTACK":
		take_damage(value)
	elif action == "potion":
		current_hp += value
	set_player_status()


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
