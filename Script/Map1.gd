extends Node2D

@onready var player = $Player
@onready var chagne_scence = $CanvasLayer/ChangeScence/AnimationPlayer
@onready var distance_label = $CanvasLayer/DistanceLabel

const MONSTER_POINT = preload("res://Scene/MonsterSpawn.tscn")
#const MONSTER = preload("res://Scene/monster.tscn")
#const MONSTER = preload("res://Scene/Goblin.tscn")
#const MONSTER = preload("res://Scene/Skeleton.tscn")
#const MONSTER = preload("res://Scene/Mushroom1.tscn")
const MONSTER = preload("res://Scene/FlyingEye.tscn")

#var current_spawn_point
var next_spawn_x : int = 500
var last_spawn_x = 0.0      # ตำแหน่ง X ล่าสุดที่เพิ่ง spawn ไป
var spawn_distance_meters = 480.0 # ระยะทางที่ต้องวิ่งเพื่อเจอ Monster (ปรับตามความเหมาะสม)
var total_distance = 0.0 # 
var pixel_per_meter = 10.0
var show : int 

func _ready() -> void:
	if player:
		last_spawn_x = player.global_position.x
	GameEvents.monster_died.connect(plus_count)
	GameEvents.spawn_monster.connect(spawn_monster)
	chagne_scence.animation_finished.connect(_on_animation_finished)

func plus_count():
	next_spawn_x += 500

func _process(_delta: float) -> void:
	if player:
		update_distance() # อัปเดตระยะทางทุกเฟรม
		if not GameEvents.is_combat:
			check_spawn_distance()

func check_spawn_distance():
	var moved_pixel = player.global_position.x - last_spawn_x
	var moved_meters = moved_pixel / pixel_per_meter
	if moved_meters >= spawn_distance_meters:
		GameEvents.spawn_monster.emit()
		#next_spawn_x += 500
		last_spawn_x = player.global_position.x

#func check_spawn_distance():
	#var moved_pixel = player.global_position.x - last_spawn_x
	#var moved_meters = moved_pixel / pixel_per_meter
	#if moved_meters >= spawn_distance_meters:
		#last_spawn_x += (spawn_distance_meters * pixel_per_meter) 
		#GameEvents.spawn_monster.emit()
		##spawn_point()


func update_distance():
	total_distance = player.global_position.x / pixel_per_meter
	show = next_spawn_x - total_distance
	distance_label.text = str(floor(show)) + " m"


#func spawn_point():
	#if player:
		#var spawn_pos = player.global_position + Vector2(0, -12)
		#current_spawn_point = MONSTER_POINT.instantiate() # เก็บไว้ในตัวแปร
		#current_spawn_point.global_position = spawn_pos
		#add_child(current_spawn_point)

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
		#if is_instance_valid(current_spawn_point):
			#current_spawn_point.queue_free()
			#current_spawn_point = null # ล้างค่าตัวแปร

func _on_animation_finished(anim_name: StringName):
	# เช็คว่าอนิเมชั่นที่จบคือ OpenMonFigth ใช่หรือไม่
	if anim_name == "OpenMonFigth":
		$CanvasLayer/ChangeScence.visible = false
		$Player/PlayerHp.visible = true
		
		$Player/BuffDebuff.visible = true
		GameEvents.is_combat = true
		$CanvasLayer/Question/EquationContainer.visible = true
		$CanvasLayer/Question.generate_dynamic_question()
