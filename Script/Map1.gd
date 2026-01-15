extends Node2D

@onready var player = $Player
@onready var chagne_scence = $CanvasLayer/ChangeScence/AnimationPlayer
@onready var distance_label = $CanvasLayer/Route/RouteIcon/DistanceLabel
@onready var RouteIcon = $CanvasLayer/Route/RouteIcon

const MONSTER_POINT = preload("res://Scene/MonsterSpawn.tscn")
#const MONSTER = preload("res://Scene/monster.tscn")
#const MONSTER = preload("res://Scene/Goblin.tscn")
#const MONSTER = preload("res://Scene/Skeleton.tscn")
#const MONSTER = preload("res://Scene/Mushroom1.tscn")
const MONSTER = preload("res://Scene/FlyingEye.tscn")
@onready var SHOP = $CanvasLayer/ShopControl

var last_spawn_x = 0.0      # ตำแหน่ง X ล่าสุดที่เพิ่ง spawn ไป
var spawn_distance_meters = 500.0 # ระยะทางที่ต้องวิ่งเพื่อเจอ Monster (ปรับตามความเหมาะสม)
var total_distance = 0.0 # 
var pixel_per_meter = 10.0


func _ready() -> void:
	if player:
		last_spawn_x = player.global_position.x
	GameEvents.spawn_monster.connect(spawn_monster)
	chagne_scence.animation_finished.connect(_on_animation_finished)


func _process(_delta: float) -> void:
	if player:
		update_distance()
		if not GameEvents.is_combat:
			check_spawn_distance()

func check_spawn_distance():
	var moved_pixel = player.global_position.x - last_spawn_x
	var moved_meters = moved_pixel / pixel_per_meter
	if moved_meters >= spawn_distance_meters:
		SHOP._on_shop_selected()
		#GameEvents.spawn_monster.emit()
		last_spawn_x = player.global_position.x

func update_distance():
	total_distance = player.global_position.x / pixel_per_meter
	distance_label.text = str(floor(total_distance)) + " m"

func spawn_monster():
	$CanvasLayer/Question/EquationContainer.visible = false 
	$CanvasLayer/ChangeScence.visible = true
	chagne_scence.play("OpenMonFigth")
	if player:
		var spawn_pos = player.global_position + Vector2(110, -15)
		var instance = MONSTER.instantiate()
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
