extends Node2D
# main.gd

@onready var chagne_scence_animad = $CanvasLayer/ChangeScence/AnimationPlayer
@onready var scene_container = $PlaySceneContainer 
@onready var fade_rect = $CanvasLayer/ChangeScence/ColorRect

func _ready() -> void:
	# เชื่อมต่อสัญญาณจาก Map (อย่าลืมประกาศสัญญาณนี้ใน GameEvents)
	GameEvents.first_room_selected.connect(_on_first_selection)
	GameEvents.fade_out_cut.connect(_switch_to_world)

func _on_first_selection():
	GameEvents.into_out_cut.emit()

# main.gd

func _switch_to_world():
	# 1. ลบซีนเก่าออกตามปกติ
	for child in scene_container.get_children():
		child.queue_free()
	
	# 2. โหลดซีน World
	var world_scene = load("res://Scene/World.tscn")
	var world_instance = world_scene.instantiate()
	scene_container.add_child(world_instance)
	
	# 3. จัดการ Player ที่อยู่ในซีน World ที่เพิ่งโหลดมา
	# สมมติว่าโครงสร้างคือ World/Player (ปรับตาม image_1fc224.png ของคุณ)
	#var player = world_instance.get_node_or_null("Player")
	#if player:
		## ปลดล็อกให้เริ่มวิ่ง (is_not_ready = false)
		#player.is_not_ready = false
		#player.activate_player_camera()
		# เปิดใช้งานกล้องของ Player และทำให้เป็นกล้องหลัก

	#await get_tree().process_frame
	#$CanvasLayer/NumpadPanel.grab_initial_focus()
