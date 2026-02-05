extends Control

const REWARD_BUTTON_SCENE = preload("res://Scene/ActionButtom.tscn")
@onready var reward_container = $RewardPanel/RewardContainer/VBoxContainer

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
		"icon": preload("res://Resouce/Util/Gold.tres")
	}
}

func _ready() -> void:
	GameEvents.reward.connect(mons_die)
	GameEvents.campfire_opened.connect(camp_open)
	GameEvents.event_opened.connect(event_open)
	GameEvents.treasure_opened.connect(treasure_open)
	GameEvents.shop_opened.connect(shop_open)
	
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
	
	# 1. ล้างรางวัลเก่าออกก่อน
	for child in reward_container.get_children():
		child.queue_free()
	
	# 2. กำหนดจำนวนช่องรางวัลพื้นฐานเป็น 3 ชิ้นตามที่คุณต้องการ
	var luck_percent = EffectProcessor.get_passive_bonus(BaseEffect.StatType.DROP_RATE)
	var total_slots = 3 
	
	# ใช้ Luck สุ่มเพิ่มโอกาสได้ช่องที่ 4 และ 5 (Bonus Slots)
	if randf() <= (luck_percent / 100.0):
		total_slots += 1
		if randf() <= (luck_percent / 100.0):
			total_slots += 1
	
	rewards_remaining = total_slots
	skip_label.text = "Skip Rewards (" + str(rewards_remaining) + ")"
	
	# 3. สร้างรางวัลตามจำนวนช่องที่กำหนด
	for i in range(total_slots):
		var new_btn = REWARD_BUTTON_SCENE.instantiate()
		reward_container.add_child(new_btn)
		
		# สุ่มประเภทรางวัลให้หลากหลาย (Skill, Gold, Equipment)
		var rand_type = i % 3
		match rand_type:
			0:
				_randomize_skill_reward(new_btn)
			1:
				_randomize_gold_reward(new_btn)
			2:
				# เรียกใช้ฟังก์ชันดรอปไอเทมที่เราเตรียมไว้
				_randomize_equipment_reward(new_btn)
		
		# เชื่อมต่อสัญญาณเมื่อกดรับ
		new_btn.pressed.connect(_on_reward_selected.bind(new_btn))
	
	# 4. Focus ไปที่อันแรก
	await get_tree().process_frame
	if reward_container.get_child_count() > 0:
		reward_container.get_child(0).grab_focus()

func _randomize_skill_reward(btn):
	var selected_skill = PlayerData.all_skills.pick_random()
	btn.set_butt_action(selected_skill.icon, selected_skill.title, 1) # เลข 1 คือจำนวนเลเวล
	btn.set_meta("reward_type", "SKILL")
	btn.set_meta("skill_resource", selected_skill)

func _randomize_equipment_reward(btn: Button):
	var item_pool = PlayerData.all_equipments
	if item_pool.is_empty(): 
		print("Item Pool is Empty!") # เช็คว่า Array มีของจริงไหม
		return
	var selected_item = item_pool.pick_random()
	print("สุ่มได้ไอเทม: ", selected_item.title) # ถ้าขึ้นชื่อไอเทม แสดงว่าโหลด Resource สำเร็จ
	print("ไอคอนไอเทม: ", selected_item.icon) # ถ้าขึ้น [null] แสดงว่าลืมลากรูปลงในไฟล์ .tres
	btn.set_meta("reward_type", "EQUIPMENT")
	btn.set_meta("item_resource", selected_item)
	
	# ตอนนี้โหนดลูก (Label/Icon) พร้อมใช้งานแล้ว
	if btn.has_method("set_butt_action"):
		btn.set_butt_action(selected_item.icon, selected_item.title, 1)
		#if not btn.is_node_ready():
			#await btn.ready # รอจนกว่าโหนดลูกของปุ่มจะโหลดเสร็จ
	else:
		# กรณีฉุกเฉินถ้าฟังก์ชันไม่ทำงาน ให้ลองเช็คชื่อโหนดข้างใน
		print("Error: ActionButton ready but set_butt_action failed")

# ฟังก์ชันสุ่มทองสำหรับปุ่มรางวัล (บวกโบนัสจาก Luck)
func _randomize_gold_reward(btn):
	var luck_bonus = EffectProcessor.get_passive_bonus(BaseEffect.StatType.DROP_RATE)
	var base_gold = randi_range(100, 200)
	# เพิ่มทองตามค่า Luck %
	var total_gold = base_gold + int(base_gold * (luck_bonus / 100.0))
	
	var gold_icon = preload("res://Resouce/Util/Gold.tres")
	btn.set_butt_action(gold_icon, "Gold Coins", total_gold)
	btn.set_meta("reward_type", "GOLD")
	btn.set_meta("amount", total_gold)


func _on_reward_selected(btn: Button):
	var type = btn.get_meta("reward_type")
	
	# จัดการรางวัลแต่ละประเภท
	if type == "SKILL":
		GameEvents.add_skill.emit(btn.get_meta("skill_resource"), 1)
	elif type == "GOLD":
		PlayerData.add_money(btn.get_meta("amount"))
	elif type == "EQUIPMENT":
		# ดึง Resource ออกมาแล้วส่งเข้าสวมใส่ (Replace ระบบเดิมที่เราเขียน)
		var item_res = btn.get_meta("item_resource")
		PlayerData.equip_item(item_res)
	
	# อัปเดตจำนวนที่เหลือ
	rewards_remaining -= 1
	
	# เล่น Effect หายไป (Tween)
	var tween = create_tween()
	tween.tween_property(btn, "modulate:a", 0.0, 0.1)
	tween.tween_callback(btn.queue_free)
	
	await tween.finished
	
	# จัดการ Focus และสถานะปุ่ม Skip
	if rewards_remaining > 0:
		skip_label.text = "Skip Rewards (" + str(rewards_remaining) + ")"
		_manage_focus_after_selection()
	else:
		skip_label.text = "Next"
		skip_button.grab_focus()

func _manage_focus_after_selection():
	# หาปุ่มแรกที่ยังเหลืออยู่ใน Container เพื่อ Grab Focus
	for child in reward_container.get_children():
		if not child.is_queued_for_deletion():
			child.grab_focus()
			return
	skip_button.grab_focus()


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
