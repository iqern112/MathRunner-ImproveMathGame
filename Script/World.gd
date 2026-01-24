extends Node2D

@onready var player = $Player
@onready var chagne_scence = $CanvasLayer/ChangeScence/AnimationPlayer
@onready var distance_label = $CanvasLayer/Route/RouteIcon/DistanceLabel
@onready var RouteIcon = $CanvasLayer/Route/RouteIcon
@onready var spawn_node = $SpawnNode

var route_scenes = {
	"MONSTER": preload("res://Scene/Route/MonsterSpawn.tscn"),
	"CAMPFIRE": preload("res://Scene/Route/CampFire.tscn"),
	"EVENT": preload("res://Scene/Route/Event.tscn"),
	"SHOP": preload("res://Scene/Route/Shop.tscn"),
	"TREASURE": preload("res://Scene/Route/Treasure.tscn"),
	"ELITE": preload("res://Scene/Route/MonsterSpawn.tscn"), # ใช้จุดสปอนมอนเหมือนกัน
	"BOSS": preload("res://Scene/Route/MonsterSpawn.tscn")
}

var current_spawn_point = null # เก็บอ้างอิงของจุดสปอนปัจจุบัน

@onready var SHOP = $CanvasLayer/ShopControl
@onready var world_cam = $Camera2D
@onready var player_cam = $Player/Camera2D

var monster_scenes = [
	preload("res://Scene/Monster/Goblin.tscn"),
	preload("res://Scene/Monster/Skeleton.tscn"),
	preload("res://Scene/Monster/Mushroom1.tscn"),
	preload("res://Scene/Monster/FlyingEye.tscn")
]

var next_event_type # เริ่มต้นบังคับเป็น Monster ตัวแรก
var event_interval = 100.0 # ระยะห่างแต่ละเหตุการณ์

var last_spawn_x = 0.0      # ตำแหน่ง X ล่าสุดที่เพิ่ง spawn ไป
var spawn_distance_meters = 500.0 # ระยะทางที่ต้องวิ่งเพื่อเจอ Monster (ปรับตามความเหมาะสม)
var total_distance = 0.0 # 
var pixel_per_meter = 10.0


func _ready() -> void:
	if player:
		last_spawn_x = player.global_position.x
	GameEvents.spawn_monster.connect(spawn_monster)
	GameEvents.shop_closed.connect(_on_event_finished)
	
	chagne_scence.animation_finished.connect(_on_animation_finished)
	GameEvents.route_changed.connect(_on_route_chosen)
	GameEvents.monster_died.connect(_on_event_finished)
	
	GameEvents.open_close_nam.connect(open_close_nam)
	play_open_scece()

func play_open_scece():
	world_cam.enabled = true
	world_cam.make_current()
	$Player/AnimationPlayer.play("cam_fade_in")

func _process(_delta: float) -> void:
	if player:
		update_distance()



#func trigger_next_event():
	## ดึงประเภทเหตุการณ์จาก Global มาเช็ค
	#var event_type = GameEvents.current_route_type 
	#
	#match event_type:
		#"MONSTER":
			#GameEvents.spawn_monster.emit()
		#"SHOP":
			#SHOP._on_shop_selected()
		#"CAMPFIRE": # ใน Enum คุณใช้ CAMPFIRE
			#GameEvents.control_to_player.emit("potion", 10)
			#_on_event_finished()
		#"TREASURE":
			#GameEvents.add_money(100)
			#_on_event_finished()
		#"ELITE":
			## คุณสามารถใช้ระบบเดียวกับ Monster แต่เปลี่ยนความยาก
			#GameEvents.spawn_monster.emit() 
		#"BOSS":
			## Logic สำหรับ Boss
			#GameEvents.spawn_monster.emit() 
		#"EVENT":
			#_on_event_finished()
		#_:
			#_on_event_finished()

func _on_event_finished():
	GameEvents.open_map.emit()

func _on_route_chosen(type: String):
	open_close_nam("open")
	$CanvasLayer/NumpadPanel.grab_initial_focus()
	GameEvents.current_route_type = type # อัปเดต Global
	GameEvents.is_stop = false
	spawn_route_point()


func update_distance():
	if is_instance_valid(current_spawn_point):
		# หาระยะห่างเป็นพิกเซล แล้วแปลงเป็นเมตร
		var distance_to_point = current_spawn_point.global_position.x - player.global_position.x
		var remaining_meters = max(0, distance_to_point / pixel_per_meter)
		
		distance_label.text = str(floor(remaining_meters)) + " m"
	else:
		distance_label.text = "--- m"

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

func spawn_route_point():
	var type = GameEvents.current_route_type
	if not route_scenes.has(type): return
	for child in spawn_node.get_children():
		child.queue_free()
	var scene = route_scenes[type]
	var instance = scene.instantiate()
	var spawn_x = player.global_position.x + (event_interval * pixel_per_meter)
	instance.global_position = Vector2(spawn_x, player.global_position.y + 15)
	spawn_node.add_child(instance)
	current_spawn_point = instance

func _on_animation_finished(anim_name: StringName):
	if anim_name == "OpenMonFigth":
		$CanvasLayer/ChangeScence.visible = false
		$Player/PlayerHp.visible = true
		$Player/BuffDebuff.visible = true
		GameEvents.is_stop = true
		$CanvasLayer/Question/EquationContainer.visible = true
		$CanvasLayer/Question.generate_dynamic_question()

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "cam_fade_in":
		#get_tree().paused = true
		#player.activate_player_camera()
		#GameEvents.cam_fade_in.emit()
		$CanvasLayer/LevelControl.visible = false
		$CanvasLayer/Wish.show()
	
		spawn_route_point() 
		
		#$CanvasLayer/NumpadPanel.visible = true
		#$CanvasLayer/NumpadPanel.grab_initial_focus()
		#$CanvasLayer/Question.visible = true
		

func open_close_nam(name : String):
	if name == "close":
		$CanvasLayer/NumpadPanel.visible = false
		$CanvasLayer/Question.visible = false
		$CanvasLayer/Route.visible = false
		$CanvasLayer/LevelControl.visible = false
	elif name == "open":
		$CanvasLayer/NumpadPanel.visible = true
		$CanvasLayer/Question.visible = true
		$CanvasLayer/Route.visible = true
		$CanvasLayer/LevelControl.visible = true
