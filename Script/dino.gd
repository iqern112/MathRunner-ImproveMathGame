extends CharacterBody2D

@export var player: CharacterBody2D  # ลากตัวละครหลักมาใส่ในช่องนี้ที่ Inspector
@export var base_speed = 240.0       # ความเร็วพื้นฐานของไดโนเสาร์
var current_speed = 240.0
# ในสคริปต์ Dinosaur.gd

func _physics_process(_delta):
	# 1. วิ่งไปทางขวาตลอดเวลา
	var main_node = get_parent()
	current_speed = base_speed + (main_node.elapsed_time * 3.0) 
	velocity.x = current_speed
	move_and_slide()
	check_collision_with_player()
	print("dino:")
	print(current_speed)

func check_collision_with_player():
	# คำนวณระยะห่างระหว่างไดโนเสาร์กับผู้เล่น
	var distance = player.global_position.x - global_position.x

	if distance <= 190:
		$"../CanvasLayer/GameOverUI".game_over()
