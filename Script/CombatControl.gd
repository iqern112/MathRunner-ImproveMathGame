extends Control

const ACTION_BUTT = preload("res://Scene/ActionButtom.tscn")

@onready var action_list = $Panel/ActionSelect/VBoxContainer
@onready var item_list = $Panel/ItemList/VBoxContainer

var current_tab: int = 0
var bonus_damage: int = 0
var bonus_shield: int = 0
var damage_reduction: int = 0

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
	# ล้างและสร้างปุ่มไอเทมใหม่ตามของที่มีในตัว (own_item)
	for child in item_list.get_children():
		child.queue_free()
	
	# ดึงข้อมูลจาก GameEvents (Singleton)
	var items = GameEvents.own_item 
	
	for item_key in items:
		var count = items[item_key]
		var data = GameEvents.data_items[item_key]
		var new_btn = ACTION_BUTT.instantiate()
		item_list.add_child(new_btn)
		new_btn.set_butt_action(data["icon"], str(data["title"]), int(count))
		new_btn.pressed.connect(_on_item_used.bind(item_key))
	await get_tree().process_frame
	if item_list.get_child_count() > 0:
		item_list.get_child(0).grab_focus()

func _on_item_used(item_key):
	GameEvents.own_item[item_key] -= 1
	if GameEvents.own_item[item_key] <= 0:
		GameEvents.own_item.erase(item_key)
	$"../ShopControl".update_item_hud_display()
	# ปิดเมนูและส่งผลไอเทม
	$Panel.visible = false
	set_item_panel()
	GameEvents.combat_panel_open.emit("close")
	if item_key == "armor":
		damage_reduction += 1
		GameEvents.item_used.emit("ReduceDamage")
	elif item_key == "shield":
		bonus_shield += 3
		GameEvents.item_used.emit("ReduceDamage")
	elif item_key == "sword":
		bonus_damage += 3
		GameEvents.item_used.emit("ReduceDamage")
	elif item_key == "bow":
		if not buff_count.has("bow"):
			buff_count["bow"] = 1
		else:
			buff_count["bow"] += 1
		bonus_damage += 10
		GameEvents.item_used.emit("ReduceDamage")
	elif item_key == "drill":
		if not buff_count.has("drill"):
			buff_count["drill"] = 1
		else:
			buff_count["drill"] += 1
		GameEvents.item_used.emit("ReduceDamage")
	elif item_key == "potion":
		GameEvents.control_to_player.emit(item_key,5)
		GameEvents.item_used.emit("ReduceDamage")
	set_up_combat_panel()
	#GameEvents.item_used.emit(item_key) # ส่งสัญญาณว่าใช้ไอเทม
	await get_tree().process_frame # รอ 1 เฟรมให้ UI อื่นๆ อัปเดตเสร็จ
	$"../NumpadPanel/GridContainer/1".grab_focus()
	$"../Question/EquationContainer".visible = true

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
	
	# ปิดหน้าต่างเลือกคำสั่ง
	$Panel.visible = false
	
	# แยกการทำงานตามชื่อที่กดมา
	match action_name:
		"Attack":
			if buff_count.get("drill", 0) > 0:
				buff_count["drill"] -= 1
				GameEvents.control_to_monster.emit("Drill",cal_all_p_damage())
				
			else : 
				GameEvents.control_to_monster.emit("Attack",cal_all_p_damage())
			if buff_count.get("bow", 0) > 0:
				buff_count["bow"] -= 1
				bonus_damage -= 10
		"Block":
			GameEvents.control_to_player.emit("Block",cal_block())
	await get_tree().process_frame
	set_up_combat_panel()
	$"../Question/EquationContainer".visible = true
	$"../NumpadPanel/GridContainer/1".grab_focus()
	GameEvents.combat_panel_open.emit("close")

func cal_all_p_damage():
	return 5 + bonus_damage

func cal_block():
	return 5 + bonus_shield

func effect_bonus_stats(skill_name, value):
	if skill_name == "power":
		bonus_damage += value
	elif skill_name == "shield":
		bonus_shield += value
	elif skill_name == "armor":
		damage_reduction += value
	set_up_combat_panel()

func mons_act_handle(act,value):
	if act == "ATTACK":
		var damage = value - damage_reduction
		GameEvents.control_to_player.emit(act,damage)


func show_action_panel():
	current_tab = 0 # กลับมาหน้าแรกทุกครั้งที่เปิด
	switch_tab()
	GameEvents.combat_panel_open.emit("open")
	$Panel.visible = true
	$"../Question/EquationContainer".visible = false
	# เลือกปุ่มแรกที่มีอยู่ใน VBoxContainer ปัจจุบัน
	#if action_list.get_child_count() > 0:
		#action_list.get_child(0).grab_focus()
