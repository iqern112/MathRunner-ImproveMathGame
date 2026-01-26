extends Control

# อ้างอิงโหนดที่คุณเตรียมไว้แล้ว
@onready var reward_rect1 = $RewardPanel/RewardContainer/Button/NinePatchRect
@onready var reward_rect2 = $RewardPanel/RewardContainer/Button2/NinePatchRect
@onready var stack_label1 = $RewardPanel/RewardContainer/Button/NinePatchRect/Label2
@onready var stack_label2 = $RewardPanel/RewardContainer/Button2/NinePatchRect/Label2

# อ้างอิงปุ่ม
@onready var btn1 = $RewardPanel/RewardContainer/Button
@onready var btn2 = $RewardPanel/RewardContainer/Button2

@onready var rest_btn = $CampfirePanel/HBoxContainer/Button
@onready var anvil_btn = $CampfirePanel/HBoxContainer/Button2

@onready var event_btn = $EventPanel/HBoxContainer/Button
@onready var leave_btn = $EventPanel/HBoxContainer/Button2

@onready var treasure1_btn = $TreasurePanel/HBoxContainer/Button
@onready var treasure2_btn = $TreasurePanel/HBoxContainer/Button2

@onready var shop1_btn = $ShopPanel/HBoxContainer/Button
@onready var shop2_btn = $ShopPanel/HBoxContainer/Button2

# ส่วนบนของสคริปต์
@onready var skip_button = $RewardPanel/Button3
@onready var skip_label = $RewardPanel/Button3/Label

var rewards_remaining = 0

var monney = {
	"gold": {
		"title": "Gold", 
		"desc": "Receive gold coins for shopping.", 
		"icon": preload("res://Resouce/SkillData1/Gold.tres")
	}
}

func _ready() -> void:
	GameEvents.reward.connect(mons_die)
	GameEvents.campfire_opened.connect(camp_open)
	GameEvents.event_opened.connect(event_open)
	GameEvents.treasure_opened.connect(treasure_open)
	GameEvents.shop_opened.connect(shop_open)
	
	btn1.pressed.connect(_on_reward_selected.bind(btn1))
	btn2.pressed.connect(_on_reward_selected.bind(btn2))
	
	rest_btn.pressed.connect(camfire_select.bind(rest_btn,"rest"))
	anvil_btn.pressed.connect(camfire_select.bind(anvil_btn,"anvil"))
	
	event_btn.pressed.connect(event_select.bind(event_btn,"event"))
	leave_btn.pressed.connect(event_select.bind(leave_btn,"leave"))
	
	treasure1_btn.pressed.connect(treasur_select.bind(treasure1_btn,"treasure"))
	treasure2_btn.pressed.connect(treasur_select.bind(treasure2_btn,"leave"))
	
	shop1_btn.pressed.connect(shop_select.bind(shop1_btn))
	shop2_btn.pressed.connect(shop_select.bind(shop2_btn))
	
	skip_button.pressed.connect(_on_skip_pressed)

func _on_skip_pressed():
	# ปิดหน้าต่างรางวัล ไม่ว่าจะกดตอนเป็น Skip หรือ Next
	$RewardPanel.visible = false
	GameEvents.open_map.emit()

func shop_open():
	GameEvents.open_close_nam.emit("close")
	$ShopPanel.visible = true
	$ShopPanel/HBoxContainer/Button.grab_focus()

func treasure_open():
	GameEvents.open_close_nam.emit("close")
	$TreasurePanel.visible = true
	$TreasurePanel/HBoxContainer/Button.grab_focus()

func event_open():
	GameEvents.open_close_nam.emit("close")
	$EventPanel.visible = true
	$EventPanel/HBoxContainer/Button.grab_focus()

func camp_open():
	GameEvents.open_close_nam.emit("close")
	$CampfirePanel.visible = true
	$CampfirePanel/HBoxContainer/Button.grab_focus()

func mons_die():
	$RewardPanel.visible = true
	GameEvents.open_close_nam.emit("close")
	
	# --- จุดสำคัญ: ต้องรีเซ็ตค่า Modulate และสถานะปุ่มกลับมาด้วย ---
	btn1.modulate.a = 1.0
	btn1.disabled = false
	btn1.show()
	
	btn2.modulate.a = 1.0
	btn2.disabled = false
	btn2.show()
	
	rewards_remaining = 2
	skip_label.text = "Skip Reward"
	
	setup_skill_reward(reward_rect1, stack_label1, btn1)
	setup_gold_reward(reward_rect2, stack_label2, btn2)
	
	btn1.grab_focus()



func setup_skill_reward(rect: NinePatchRect, stack: Label, btn: Button):
	# ดึงจาก Global ตรงๆ
	if PlayerData.all_skills.is_empty(): return
	
	var selected_skill = PlayerData.all_skills.pick_random()
	
	rect.texture = selected_skill.icon
	stack.text = selected_skill.title
	
	btn.set_meta("reward_type", "SKILL")
	btn.set_meta("skill_resource", selected_skill) # เก็บตัว Resource ไว้เลย
	btn.tooltip_text = selected_skill.desc

func setup_gold_reward(rect: NinePatchRect, stack: Label, btn: Button):
	var gold_data = monney["gold"]
	var amount = randi_range(100, 200)
	
	# กำหนดค่าทอง
	rect.texture = gold_data["icon"]
	stack.text = str(amount) + " Gold"
	
	btn.set_meta("reward_type", "GOLD")
	btn.set_meta("amount", amount)
	btn.tooltip_text = "Gain " + str(amount) + " Gold."

func _on_reward_selected(btn: Button):
	var type = btn.get_meta("reward_type")
	
	# 1. จัดการประมวลผลรางวัล
	if type == "SKILL":
		var skill_res = btn.get_meta("skill_resource")
		# เรียกใช้ฟังก์ชันเพิ่มสกิลที่ Global
		GameEvents.add_skill.emit(skill_res, 1)
	elif type == "GOLD":
		var amount = btn.get_meta("amount")
		PlayerData.add_money(amount)
	
	# 2. เรียกใช้แอนิเมชัน และรอให้จบก่อน (ใช้ await)
	await smooth_hide_button(btn)
	
	# 3. อัปเดตสถานะที่เหลือ
	rewards_remaining -= 1
	
	# 4. จัดการเรื่อง Focus และเปลี่ยนข้อความปุ่ม
	_manage_focus_after_selection()
	
	if rewards_remaining <= 0:
		skip_label.text = "Next"
		skip_button.grab_focus()

func _manage_focus_after_selection():
	# ตรวจสอบว่าปุ่มไหนยังมองเห็นอยู่ ให้ย้าย Focus ไปที่นั่น
	if btn1.visible:
		btn1.grab_focus()
	elif btn2.visible:
		btn2.grab_focus()
	else:
		skip_button.grab_focus()

func smooth_hide_button(btn: Button):
	var tween = create_tween()
	# กันผู้เล่นกดซ้ำระหว่างแอนิเมชัน
	btn.disabled = true
	
	# ค่อยๆ จางหาย
	tween.tween_property(btn, "modulate:a", 0.0, 0.2)
	
	# เมื่อจางหายเสร็จ ให้สั่งซ่อน เพื่อให้ VBoxContainer เลื่อนอันล่างขึ้นมา
	tween.tween_callback(btn.hide)
	
	# ส่งสัญญาณกลับเพื่อให้ฟังก์ชันหลักทำงานต่อหลังจบ Tween
	return tween.finished

func camfire_select(btn: Button,action: String):
	if action == "rest":
		GameEvents.control_to_player.emit("potion",10)
	#GameEvents.open_close_nam.emit("open")
	btn.release_focus()
	$CampfirePanel.visible = false
	GameEvents.open_map.emit()

func event_select(btn: Button,action: String):
	if action == "event":
		PlayerData.add_money(300)
	#GameEvents.open_close_nam.emit("open")
	btn.release_focus()
	$EventPanel.visible = false
	GameEvents.open_map.emit()

func treasur_select(btn: Button,action):
	if action == "treasure":
		PlayerData.add_money(300)
	#GameEvents.open_close_nam.emit("open")
	btn.release_focus()
	$TreasurePanel.visible = false
	GameEvents.open_map.emit()

func shop_select(btn: Button):
	#GameEvents.open_close_nam.emit("open")
	btn.release_focus()
	$ShopPanel.visible = false
	GameEvents.open_map.emit()
