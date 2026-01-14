extends Control

const ACTION_BUTT = preload("res://Scene/ActionButtom.tscn")
const BUFF_ICON = preload("res://Scene/SkillOnItem.tscn")
const ON_SELECT_ACT = preload("res://Theme/ActionSelected.tres")

@onready var buff_show = $"../../Player/BuffDebuff"
@onready var action_list = $Panel/ActionSelect/VBoxContainer
@onready var item_list = $Panel/ItemList/VBoxContainer
@onready var action_head = $Panel/HBoxContainer/Action
@onready var item_head = $Panel/HBoxContainer/Item

var current_tab: int = 0
var bonus_damage: int = 0
var bonus_shield: int = 0
var damage_reduction: int = 0

# ข้อมูลไอคอนและชื่อบัฟทั้งหมด (แนะนำให้ย้ายไป GameEvents หรือประกาศไว้ด้านบน)
var data_buffs = {
	"ReduceDamage": {"title": "Defense Up", "icon": preload("res://Resouce/Buff/ReduceDamage.tres")},
	"IcressBlock": {"title": "Shield Up", "icon": preload("res://Resouce/Buff/IcressBlock.tres")},
	"IncressDamage": {"title": "Attack Up", "icon": preload("res://Resouce/Buff/IncressDamage.tres")},
	"AddNextDmg": {"title": "Archer Buff", "icon": preload("res://Resouce/Buff/AddNextDmg.tres")},
	"Piercing": {"title": "Drill Buff", "icon": preload("res://Resouce/Buff/Piercing.tres")}
}

# ตัวแปรเก็บจำนวนบัฟที่มีอยู่ ณ ปัจจุบัน
var buff_count: Dictionary = {}

# เปลี่ยนจาก var action_key = เป็นตัวแปรเก็บสถานะการเลือก
var current_selected_action: String = ""

var data_action = {
	"Attack": {"title": "Attack", "icon": preload("res://Resouce/ActionIcon/AttackIcon.tres")},
	"Block": {"title": "Block", "icon": preload("res://Resouce/ActionIcon/BlockIcon.tres")},
}

func _ready() -> void:
	GameEvents.combat_correct.connect(show_action_panel)
	GameEvents.on_skill_recive.connect(effect_bonus_stats)
	GameEvents.monster_to_control.connect(mons_act_handle)
	set_up_combat_panel()
	

func _input(event):
	if not $Panel.visible: return
	
	# กด A (ซ้าย) หรือ D (ขวา) เพื่อสลับหน้า
	if event.is_action_pressed("ui_left"): # หรือ "ui_left"
		current_tab  = 0
		switch_tab()
	elif event.is_action_pressed("ui_right"): # หรือ "ui_right"
		current_tab = 1
		switch_tab()

func switch_tab():
	update_tab_visuals()
	if current_tab == 0:
		action_list.get_parent().visible = true
		item_list.get_parent().visible = false
		# โฟกัสปุ่มแรกของ Action
		if action_list.get_child_count() > 0:
			action_list.get_child(0).grab_focus()
	else:
		action_list.get_parent().visible = false
		item_list.get_parent().visible = true
		set_item_panel()
		 # อัปเดตรายการไอเทมก่อนโชว์

func set_item_panel():
	for child in item_list.get_children():
		child.queue_free()
	
	var items = GameEvents.own_item 
	var buttons = [] # เก็บปุ่มไว้ตั้งค่า Neighbor

	for item_key in items:
		var count = items[item_key]
		var data = GameEvents.data_items[item_key]
		var new_btn = ACTION_BUTT.instantiate()
		item_list.add_child(new_btn)
		new_btn.set_butt_action(data["icon"], str(data["title"]), int(count))
		new_btn.pressed.connect(_on_item_used.bind(item_key))
		buttons.append(new_btn)

	# --- เพิ่มส่วนนี้เพื่อจัดการ W/S (Focus) ---
	for i in range(buttons.size()):
		if i > 0:
			buttons[i].set_focus_neighbor(SIDE_TOP, buttons[i-1].get_path())
		if i < buttons.size() - 1:
			buttons[i].set_focus_neighbor(SIDE_BOTTOM, buttons[i+1].get_path())
	# ---------------------------------------

	await get_tree().process_frame
	if item_list.get_child_count() > 0:
		item_list.get_child(0).grab_focus()

func _on_item_used(item_key):
	GameEvents.own_item[item_key] -= 1
	if GameEvents.own_item[item_key] <= 0:
		GameEvents.own_item.erase(item_key)
	$"../ShopControl".update_item_hud_display()
	#$Panel.visible = false
	set_item_panel()
	add_buff(item_key)
	#GameEvents.combat_panel_open.emit("close")
	#await get_tree().process_frame # รอ 1 เฟรมให้ UI อื่นๆ อัปเดตเสร็จ
	#$"../NumpadPanel/GridContainer/1".grab_focus()
	#$"../Question/EquationContainer".visible = true

func add_buff(buff_key):
	match buff_key:
		"armor":
			buff_count["ReduceDamage"] = buff_count.get("ReduceDamage", 0) + 1
			damage_reduction += 1
		"shield":
			buff_count["IcressBlock"] = buff_count.get("IcressBlock", 0) + 1
			bonus_shield += 3
		"sword":
			buff_count["IncressDamage"] = buff_count.get("IncressDamage", 0) + 1
			bonus_damage += 3
		"bow":
			buff_count["AddNextDmg"] = buff_count.get("AddNextDmg", 0) + 1
			bonus_damage += 10
		"drill":
			buff_count["Piercing"] = buff_count.get("Piercing", 0) + 1
		"potion":
			GameEvents.control_to_player.emit(buff_key, 5)
			
	update_buff() # อัปเดตไอคอนบนหัวตัวละคร
	set_up_combat_panel() # อัปเดตตัวเลขบนปุ่ม
	

func set_up_combat_panel():
	for child in action_list.get_children():
		child.queue_free()
	
	for a_key in data_action:
		var data = data_action[a_key]
		var new_action_btn = ACTION_BUTT.instantiate()
		action_list.add_child(new_action_btn)
		
		# --- ส่วนที่เพิ่ม/แก้ไข ---
		var display_value = 0
		
		if a_key == "Attack":
			
			display_value = cal_all_p_damage() # เรียกใช้ฟังก์ชันคำนวณ 5 + bonus_damage
		elif a_key == "Block":
			display_value = cal_block()   # คำนวณค่าพลังป้องกันพื้นฐาน + โบนัส
			
		# ส่งค่า display_value ที่คำนวณแล้วเข้าไปแทนเลข 5 เดิม
		new_action_btn.set_butt_action(data["icon"], data["title"], display_value)
		# -----------------------
		
		new_action_btn.pressed.connect(_on_action_pressed.bind(a_key))


func _on_action_pressed(action_name: String):
	current_selected_action = action_name
	update_buff()
	# ปิดหน้าต่างเลือกคำสั่ง
	$Panel.visible = false
	# แยกการทำงานตามชื่อที่กดมา
	match action_name:
		"Attack":
			if buff_count.get("Piercing", 0) > 0:
				buff_count["Piercing"] -= 1
				GameEvents.control_to_monster.emit("Drill",cal_all_p_damage())
				
			else : 
				GameEvents.control_to_monster.emit("Attack",cal_all_p_damage())
			if buff_count.get("AddNextDmg", 0) > 0:
				buff_count["AddNextDmg"] -= 1
				bonus_damage -= 10
		"Block":
			GameEvents.control_to_player.emit("Block",cal_block())
	await get_tree().process_frame
	set_up_combat_panel()
	update_buff() # อัปเดตไอคอนบนหัวตัวละคร
	$"../Question/EquationContainer".visible = true
	$"../NumpadPanel/GridContainer/1".grab_focus()
	GameEvents.combat_panel_open.emit("close")

func cal_all_p_damage():
	return 5 + bonus_damage

func cal_block():
	return 5 + bonus_shield


func effect_bonus_stats(skill_name, value):
	match skill_name:
		"armor":
			buff_count["ReduceDamage"] = buff_count.get("ReduceDamage", 0) + 1
			damage_reduction += value
		"shield":
			buff_count["IcressBlock"] = buff_count.get("IcressBlock", 0) + 1
			bonus_shield += value
		"power":
			buff_count["IncressDamage"] = buff_count.get("IncressDamage", 0) + 1
			bonus_damage += value
	set_up_combat_panel()
	update_buff() # อัปเดตไอคอนบนหัวตัวละคร

func mons_act_handle(act,value):
	if act == "ATTACK":
		var damage = value - damage_reduction
		GameEvents.control_to_player.emit(act,damage)

func update_buff():
	# 1. ล้างไอคอนเก่าทิ้ง
	for child in buff_show.get_children():
		child.queue_free()
		
	# 2. วนลูปตามบัฟที่มีใน buff_count
	for b_key in buff_count:
		var count = buff_count[b_key]
		
		# แสดงเฉพาะบัฟที่มีจำนวนมากกว่า 0
		if count > 0:
			# ดึงข้อมูล Icon จาก data_buffs
			if data_buffs.has(b_key):
				var data = data_buffs[b_key]
				
				# 3. สร้าง Instance ของไอคอนบัฟ (ใช้ Scene เดียวกับที่โชว์สกิล/ไอเทม)
				var new_buff_icon = BUFF_ICON.instantiate()
				buff_show.add_child(new_buff_icon)
				
				# 4. ส่งรูปและตัวเลขไปแสดงผล
				new_buff_icon.set_skill_info(data["icon"], count)

func show_action_panel():
	current_tab = 0 # กลับมาหน้าแรกทุกครั้งที่เปิด
	switch_tab()
	update_tab_visuals()
	GameEvents.combat_panel_open.emit("open")
	$Panel.visible = true
	$"../Question/EquationContainer".visible = false
	# เลือกปุ่มแรกที่มีอยู่ใน VBoxContainer ปัจจุบัน
	#if action_list.get_child_count() > 0:
		#action_list.get_child(0).grab_focus()

func update_tab_visuals():
	# สร้าง StyleBox แบบว่างเปล่า (Empty) สำหรับแท็บที่ไม่ได้เลือก
	var empty_style = StyleBoxEmpty.new()
	
	if current_tab == 0: # หน้า Action ถูกเลือก
		action_head.add_theme_stylebox_override("panel", ON_SELECT_ACT)
		item_head.add_theme_stylebox_override("panel", empty_style)
		# อาจจะปรับความโปร่งใสของตัวอักษรด้วย (ถ้าต้องการ)
		#action_head.modulate.a = 1.0
		#item_head.modulate.a = 0.5
	else: # หน้า Item ถูกเลือก
		action_head.add_theme_stylebox_override("panel", empty_style)
		item_head.add_theme_stylebox_override("panel", ON_SELECT_ACT)
		# ปรับความโปร่งใส
		#action_head.modulate.a = 0.5
		#item_head.modulate.a = 1.0
