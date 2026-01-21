extends Node2D

@onready var player = $Player
@onready var chagne_scence = $CanvasLayer/ChangeScence/AnimationPlayer
@onready var distance_label = $CanvasLayer/Route/RouteIcon/DistanceLabel
@onready var RouteIcon = $CanvasLayer/Route/RouteIcon

const MONSTER_POINT = preload("res://Scene/Route/MonsterSpawn.tscn")

@onready var SHOP = $CanvasLayer/ShopControl

var monster_scenes = [
	preload("res://Scene/Monster/Goblin.tscn"),
	preload("res://Scene/Monster/Skeleton.tscn"),
	preload("res://Scene/Monster/Mushroom1.tscn"),
	preload("res://Scene/Monster/FlyingEye.tscn")
]

var next_event_type = "Monster" # เริ่มต้นบังคับเป็น Monster ตัวแรก
var event_interval = 500.0 # ระยะห่างแต่ละเหตุการณ์

var last_spawn_x = 0.0      # ตำแหน่ง X ล่าสุดที่เพิ่ง spawn ไป
var spawn_distance_meters = 500.0 # ระยะทางที่ต้องวิ่งเพื่อเจอ Monster (ปรับตามความเหมาะสม)
var total_distance = 0.0 # 
var pixel_per_meter = 10.0


func _ready() -> void:
	if player:
		last_spawn_x = player.global_position.x
	GameEvents.spawn_monster.connect(spawn_monster)
	chagne_scence.animation_finished.connect(_on_animation_finished)

	GameEvents.route_selected.connect(_on_route_chosen)
	GameEvents.monster_died.connect(_on_event_finished)
	GameEvents.shop_closed.connect(_on_event_finished)
	#_on_event_finished()


func _process(_delta: float) -> void:
	if player:
		update_distance()
		if not GameEvents.is_combat:
			check_spawn_distance()


func trigger_next_event():
	# ปรับให้รองรับ String จาก Enum (ตัวพิมพ์ใหญ่ทั้งหมด)
	match next_event_type:
		"MONSTER":
			GameEvents.spawn_monster.emit()
		"SHOP":
			SHOP._on_shop_selected()
		"CAMPFIRE": # ใน Enum คุณใช้ CAMPFIRE
			GameEvents.control_to_player.emit("potion", 10)
			_on_event_finished()
		"TREASURE":
			GameEvents.add_money(100)
			_on_event_finished()
		"ELITE":
			# คุณสามารถใช้ระบบเดียวกับ Monster แต่เปลี่ยนความยาก
			GameEvents.spawn_monster.emit() 
		"BOSS":
			# Logic สำหรับ Boss
			GameEvents.spawn_monster.emit() 
		"EVENT":
			_on_event_finished()
		_:
			# กรณีที่หาไม่เจอ ให้จบ Event เพื่อเลือกห้องใหม่
			print("Unknown event type: ", next_event_type)
			_on_event_finished()

func check_spawn_distance():
	var moved_pixel = player.global_position.x - last_spawn_x
	var moved_meters = moved_pixel / pixel_per_meter
	
	if moved_meters >= event_interval:
		trigger_next_event()
		last_spawn_x = player.global_position.x

func _on_event_finished():
	# หยุดวิ่ง
	GameEvents.is_combat = true
	
	# เปลี่ยนจากระบบเดิม มาใช้ระบบ Map ใหม่
	# สมมติว่าโหนด Map ของคุณอยู่ที่ $CanvasLayer/Map
	$CanvasLayer/Map.open_map() 

func _on_route_chosen(type: String):
	next_event_type = type
	
	# เมื่อเลือกทางเสร็จ แผนที่จะถูกปิดด้วยตัวเองใน Map.gd อยู่แล้ว (_on_map_room_selected)
	# เราแค่สั่งให้เริ่มวิ่ง
	GameEvents.is_combat = false
	last_spawn_x = player.global_position.x

#func check_spawn_distance():
	#var moved_pixel = player.global_position.x - last_spawn_x
	#var moved_meters = moved_pixel / pixel_per_meter
	#if moved_meters >= spawn_distance_meters:
		#SHOP._on_shop_selected()
		##GameEvents.spawn_monster.emit()
		#last_spawn_x = player.global_position.x

func update_distance():
	total_distance = player.global_position.x / pixel_per_meter
	distance_label.text = str(floor(total_distance)) + " m"

func spawn_monster():
	$CanvasLayer/Question/EquationContainer.visible = false 
	$CanvasLayer/ChangeScence.visible = true
	chagne_scence.play("OpenMonFigth")
	if player:
		var random_monster_scene = monster_scenes.pick_random()
		var instance = random_monster_scene.instantiate()
		var spawn_pos = player.global_position + Vector2(110, -15)
		instance.global_position = spawn_pos
		add_child.call_deferred(instance)

func _on_animation_finished(anim_name: StringName):
	if anim_name == "OpenMonFigth":
		$CanvasLayer/ChangeScence.visible = false
		$Player/PlayerHp.visible = true
		$Player/BuffDebuff.visible = true
		GameEvents.is_combat = true
		$CanvasLayer/Question/EquationContainer.visible = true
		$CanvasLayer/Question.generate_dynamic_question()
