extends Node2D

@onready var player = $Player
@onready var chagne_scence = $CanvasLayer/ChangeScence/AnimationPlayer

const MONSTER_POINT = preload("res://Scene/MonsterSpawn.tscn")
const MONSTER = preload("res://Scene/monster.tscn")

var current_spawn_point
var monster_spawn_timer

func _ready() -> void:
	set_up_monster()
	
	GameEvents.spawn_monster.connect(spawn_monster)
	chagne_scence.animation_finished.connect(_on_animation_finished)

func set_up_monster():
	monster_spawn_timer = Timer.new()
	monster_spawn_timer.process_mode = Node.PROCESS_MODE_ALWAYS # ✅ กัน pause ทำให้ Timer หยุด
	add_child(monster_spawn_timer)

	monster_spawn_timer.wait_time = 20.0
	monster_spawn_timer.one_shot = true
	monster_spawn_timer.timeout.connect(spawn_point)
	monster_spawn_timer.start()

func spawn_point():
	if player:
		var spawn_pos = player.global_position + Vector2(400, -12)
		current_spawn_point = MONSTER_POINT.instantiate() # เก็บไว้ในตัวแปร
		current_spawn_point.global_position = spawn_pos
		add_child(current_spawn_point)

func spawn_monster():
	$CanvasLayer/Question/EquationContainer.visible = false 
	$CanvasLayer/ChangeScence.visible = true
	chagne_scence.play("OpenMonFigth")
	if player:
		# 1. สร้าง Monster ตามปกติ
		var spawn_pos = player.global_position + Vector2(110, -15)
		var instance = MONSTER.instantiate()
		instance.global_position = spawn_pos
		add_child.call_deferred(instance)
		
		# 2. ลบ Spawn Point ออกถ้ามันยังอยู่
		if is_instance_valid(current_spawn_point):
			current_spawn_point.queue_free()
			current_spawn_point = null # ล้างค่าตัวแปร

func _on_animation_finished(anim_name: StringName):
	# เช็คว่าอนิเมชั่นที่จบคือ OpenMonFigth ใช่หรือไม่
	if anim_name == "OpenMonFigth":
		$CanvasLayer/ChangeScence.visible = false
		$Player/PlayerHp.visible = true
		
		$Player/BuffDebuff.visible = true
		GameEvents.is_combat = true
		$CanvasLayer/Question/EquationContainer.visible = true
		$CanvasLayer/Question.generate_dynamic_question()
