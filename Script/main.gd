extends Node2D
# main.gd

@onready var chagne_scence_animad = $CanvasLayer/ChangeScence/AnimationPlayer
@onready var scene_container = $PlaySceneContainer 
@onready var fade_rect = $CanvasLayer/ChangeScence/ColorRect

func _ready() -> void:
	# เชื่อมต่อสัญญาณจาก Map (อย่าลืมประกาศสัญญาณนี้ใน GameEvents)
	GameEvents.first_room_selected.connect(_on_first_selection)

func _on_first_selection():
	# --- ช่วงที่ 1: Fade Out (จอมืดลง) ---
	fade_rect.visible = true
	chagne_scence_animad.play("fade_out")
	await chagne_scence_animad.animation_finished # รอ 1.5 วิ จนจอดำสนิท
	fade_rect.visible = false # ซ่อนแผ่นสีดำเมื่อสว่างสนิทแล้ว
	# --- ช่วงที่ 2: สลับซีน (ทำตอนจอดำสนิท) ---
	_switch_to_world() # ลบแคมป์ โหลด World
	$CanvasLayer/NumpadPanel.visible = true
	$CanvasLayer/Question.visible = true
	await get_tree().process_frame
	$CanvasLayer/NumpadPanel.grab_initial_focus()
	

func _switch_to_world():
	# ลบ Intro หรือซีนเก่าทิ้ง
	for child in scene_container.get_children():
		child.queue_free()
	
	# โหลดและติดตั้ง World Instance
	var world_scene = load("res://Scene/World.tscn") 
	var world_instance = world_scene.instantiate()
	scene_container.add_child(world_instance)
