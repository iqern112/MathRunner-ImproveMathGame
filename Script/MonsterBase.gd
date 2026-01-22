extends CharacterBody2D
class_name MonsterBase

# --- Signals & Resources ---
var attack_icon = preload("res://Resouce/ActionIcon/AttackIcon.tres")
var block_icon = preload("res://Resouce/ActionIcon/BlockIcon.tres")

# --- Onready Nodes (ชื่อโหนดต้องตรงกันทุกมอนสเตอร์) ---
@onready var mons_animad = $AnimatedSprite2D
@onready var mons_action_timer = $Timer
@onready var hint_icon = $Hint/NinePatchRect
@onready var hint_value = $Hint/NinePatchRect/Label
@onready var player = $"../Player"

# --- Export Variables ---
@export var max_hp: int = 20
@export var current_hp: int = 20
@export var shield: int = 0

# --- Internal Variables ---
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var original_position: Vector2
var mons_action: String
var actions_value: int = 0
var attack_tween: Tween

func _ready() -> void:
	original_position = global_position
	set_mons_status()
	mons_animad.play("Appear")
	
	# เชื่อมต่อ Signals
	mons_action_timer.timeout.connect(_on_mons_action_timer_timeout)
	GameEvents.control_to_monster.connect(action_combat_handle)
	GameEvents.combat_panel_open.connect(on_stop_timer)
	GameEvents.game_over_triggered.connect(player_die)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	if GameEvents.is_combat:
		$Hint/time.text = " %.1d" % mons_action_timer.time_left
	move_and_slide()

# --- HP & UI Logic ---
func set_mons_status():
	$MonsterHp.max_value = max_hp
	$MonsterHp.value = current_hp
	$MonsterHp/MonsterHpLabel.text = str(current_hp) + "/" + str(max_hp)
	$MonsterShield.visible = shield > 0
	if shield > 0:
		$MonsterShield/MonsterShieldLabel.text = str(shield)

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
	
	# เล่นอนิเมชั่น Hurt ถ้าไม่ได้กำลังโจมตี
	if current_hp > 0 and mons_animad.animation != "Attack":
		mons_animad.play("Hurt")
		
	set_mons_status()
	if current_hp <= 0: die()

# --- Combat Actions ---
func prepare_mons_next_move():
	var actions = ["ATTACK", "BLOCK"]
	mons_action = actions.pick_random()
	mons_action_timer.wait_time = randf_range(5.0, 10.0)
	actions_value = randi_range(5, 10)
	mons_action_timer.start()
	
	hint_icon.texture = attack_icon if mons_action == "ATTACK" else block_icon
	hint_value.text = str(actions_value)

func move_to_player_and_attack():
	if not player: return
	var target_node = player.get_node("AttackPosition")
	if attack_tween: attack_tween.kill()
	
	attack_tween = create_tween()
	attack_tween.tween_property(self, "global_position", target_node.global_position, 0.2).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	attack_tween.tween_callback(func():
		if current_hp > 0: mons_animad.play("Attack")
	)

func _on_mons_action_timer_timeout():
	if mons_action == "ATTACK":
		move_to_player_and_attack()
	elif mons_action == "BLOCK":
		mons_animad.play("Defend")
		shield += actions_value
		set_mons_status()

# --- Signal Handlers ---
func action_combat_handle(action, value):
	if action == "Attack": take_damage(value)
	elif action == "Drill": 
		current_hp -= value
		set_mons_status()
		if current_hp <= 0: die()

func on_stop_timer(mode):
	mons_action_timer.paused = (mode == "open")

func die():
	mons_action_timer.stop()
	if attack_tween: attack_tween.kill()
	global_position = original_position
	$MonsterHp.visible = false
	$Hint.visible = false
	mons_animad.play("Death")

func player_die(_status):
	mons_action_timer.paused = true

func _on_animated_sprite_2d_animation_finished():
	var anim = mons_animad.animation
	if anim == "Appear":
		mons_animad.play("Idle")
		$MonsterHp.visible = true
		$Hint.visible = true
		prepare_mons_next_move()
	elif anim == "Attack":
		GameEvents.monster_to_control.emit(mons_action, actions_value)
		var t = create_tween()
		t.tween_property(self, "global_position", original_position, 0.2)
		mons_animad.play("Idle")
		prepare_mons_next_move()
	elif anim in ["Defend", "Hurt"]:
		mons_animad.play("Idle")
		if anim == "Defend": prepare_mons_next_move()
	elif anim == "Death":
		GameEvents.reward.emit()
		queue_free()
