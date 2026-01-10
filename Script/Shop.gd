extends Area2D

func _ready() -> void:
	# เชื่อมต่อสัญญาณเมื่อมีอะไรมาชน
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	# ตรวจสอบว่าเป็น Player หรือไม่ (เช็คจากชื่อหรือ Group)
	if body.name == "Player":
		open_shop()

func open_shop():
	# หยุดเกม
	get_tree().paused = true
	
	# ส่งสัญญาณไปบอก UI ร้านค้าให้เปิดขึ้นมา
	# (คุณสามารถสร้าง Signal ใน GameEvents หรือเรียก UI ตรงๆ)
	GameEvents.shop_opened.emit() 
	
	print("เข้าสู่ร้านค้า!")

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	await get_tree().create_timer(1).timeout
	# เมื่อตัวร้านค้าหลุดออกนอกจอทั้งหมด ให้ลบทิ้งทันที
	queue_free()
