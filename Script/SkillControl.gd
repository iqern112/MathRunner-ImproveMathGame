extends Control

@onready var numpad_button = $"../NumpadPanel/GridContainer/1"
@onready var show_skill_hbox = $ShowSkill
@onready var show_skillactive_hbox = $ShowActive
@onready var GlobalTooltip = $".."

var extra_base_reward = 0
var current_options: Array[SkillData] = [] 
var skill_ui_nodes: Dictionary = {} 
var active_skill_ui_nodes: Dictionary = {} 

func _ready() -> void:
	var all_buttons = $Panel/SkillButtonsContainer.get_children()
	for i in range(all_buttons.size()):
		var btn = all_buttons[i]
		btn.pressed.connect(_on_skill_selected.bind(i))
		# เมื่อโฟกัส หรือเมาส์เข้า ให้แสดง Tooltip
		btn.focus_entered.connect(_show_global_desc.bind(i))
		btn.mouse_entered.connect(_show_global_desc.bind(i))
		# เมื่อออกจากปุ่ม ให้ซ่อน Tooltip
		btn.focus_exited.connect(func(): GlobalTooltip.hide_info())
		btn.mouse_exited.connect(func(): GlobalTooltip.hide_info())
	GameEvents.level_up_signal.connect(select_skill)
	GameEvents.money_changed.connect(_update_money_display)
	GameEvents.add_skill.connect(_play_get_skill_anim)
	PlayerData.passive_skill_updated.connect(_update_passive_ui)
	PlayerData.active_skill_updated.connect(_update_active_ui)
	GameEvents.game_over_triggered.connect(func(): if not visible: clear_hud())

func _update_passive_ui(skill: SkillData, stack: int):
	_display_on_hud(skill, stack, skill_ui_nodes, show_skill_hbox)

# สำหรับแสดง Active (แถวล่าง)
func _update_active_ui(skill: SkillData, stack: int):
	_display_on_hud(skill, stack, active_skill_ui_nodes, show_skillactive_hbox)

func select_skill():
	if $Panel.visible: return
	
	# 1. คำนวณจำนวนช่องเลือก (เหมือนเดิม)
	var pick_amount = 3 
	var luck_percent = EffectProcessor.get_passive_bonus(BaseEffect.StatType.DROP_RATE)
	if randf() <= (luck_percent / 100.0):
		pick_amount += 1
		if randf() <= (luck_percent / 100.0):
			pick_amount += 1

	# --- 2. กระบวนการสร้าง Pool แบบแยกประเภท ---
	var pool: Array[SkillData] = []
	
	# แยกสกิลทั้งหมดที่มีในเกมออกเป็น 2 กลุ่ม
	var all_passives = PlayerData.all_skills.filter(func(s): return s.is_passive)
	var all_actives = PlayerData.all_skills.filter(func(s): return not s.is_passive)
	
	# แยกสกิลที่ผู้เล่นมีอยู่แล้วออกเป็น 2 กลุ่ม
	var owned_passives = PlayerData.own_skills.keys().filter(func(s): return s.is_passive)
	var owned_actives = PlayerData.own_skills.keys().filter(func(s): return not s.is_passive)

	# ตรวจสอบเงื่อนไข Passive: ถ้ายังไม่ครบ 5 สุ่มอันใหม่ได้ ถ้าครบแล้วสุ่มได้เฉพาะอันเก่า
	if owned_passives.size() < 5:
		pool.append_array(all_passives)
	else:
		pool.append_array(owned_passives)
		
	# ตรวจสอบเงื่อนไข Active: ถ้ายังไม่ครบ 5 สุ่มอันใหม่ได้ ถ้าครบแล้วสุ่มได้เฉพาะอันเก่า
	if owned_actives.size() < 5:
		pool.append_array(all_actives)
	else:
		pool.append_array(owned_actives)
		
	# กำจัดตัวซ้ำ (ถ้ามี) และทำการ Shuffle
	pool.shuffle()
	
	# 3. เลือกสกิลมาแสดงผล (เหมือนเดิม)
	pick_amount = min(pick_amount, pool.size())
	current_options = pool.slice(0, pick_amount)
	
	# --- การแสดงผลบน UI ---
	var buttons = $Panel/SkillButtonsContainer.get_children()
	for b in buttons: b.visible = false
	
	for i in range(current_options.size()):
		buttons[i].visible = true
		buttons[i].get_node("NinePatchRect").texture = current_options[i].icon
	
	get_tree().paused = true
	$Panel.visible = true
	buttons[0].grab_focus()
	
	if has_node("../Question/EquationContainer"):
		$"../Question/EquationContainer".visible = false

func _show_global_desc(index: int):
	if index < current_options.size():
		var skill = current_options[index]
		# เรียกใช้ Global Tooltip ที่เป็น Autoload
		GlobalTooltip.show_info(skill.title, skill.desc)


func _on_skill_selected(index: int):
	var selected_skill = current_options[index]
	# ส่งสัญญาณออกไปให้โลกภายนอกรู้ (PlayerData และ HUD จะรับช่วงต่อเอง)
	GameEvents.add_skill.emit(selected_skill, 1)
	
	$Panel.visible = false
	get_tree().paused = false
	if numpad_button: numpad_button.grab_focus()
	
	if has_node("../Question/EquationContainer"):
		$"../Question/EquationContainer".visible = true
	
	# --- เพิ่มตรงนี้: เช็คว่า EXP ที่ทบไว้ มันยังล้นหลอดอยู่ไหม ---
	# ถ้าล้น ให้สั่งเปิดหน้าเลือกสกิลอีกครั้งในเฟรมถัดไป
	_check_for_next_level()

func _check_for_next_level():
	# รอ 1 เฟรมให้ UI ปิดสนิทก่อน
	await get_tree().process_frame 
	
	# อ้างอิงไปที่โหนด LevelControl
	var level_sys = get_node_or_null("../LevelControl")
	
	if level_sys:
		# ถ้า EXP ยังล้นหลอดอยู่ (ทบมาเยอะ)
		if level_sys.current_exp >= level_sys.level_bar.max_value:
			print("EXP ยังล้นอยู่ ส่งสัญญาณเลเวลอัปอีกรอบ!")
			
			# เรียกสัญญาณเดิมซ้ำ เพื่อให้ select_skill() ทำงานอีกครั้ง
			GameEvents.level_up_signal.emit()


func _display_on_hud(skill: SkillData, stack: int, storage: Dictionary, container: HBoxContainer):
	if storage.has(skill):
		# ถ้ามีใน Dictionary แล้ว ให้เรียกใช้ฟังก์ชันของโหนดนั้นเพื่ออัปเดต
		storage[skill].set_skill_info(skill.icon, stack)
	else:
		var idx = storage.size()
		if idx < container.get_child_count():
			var target_node = container.get_child(idx)
			
			# เรียกใช้ฟังก์ชัน set_skill_info เหมือนที่เคยทำใน smart_update_hud
			if target_node.has_method("set_skill_info"):
				target_node.set_skill_info(skill.icon, stack)
			else:
				# กรณีฉุกเฉินถ้าโหนดไม่มีสคริปต์ ให้เซ็ตแบบแมนนวล
				target_node.texture = skill.icon
				if target_node.has_node("Label"):
					target_node.get_node("Label").text = str(stack)
			# บันทึกลง Dictionary
			storage[skill] = target_node

func _play_get_skill_anim(_skill: SkillData, _amount: int):
	var player_anim = get_node_or_null("../../Player/AnimationPlayer")
	if player_anim:
		player_anim.play("exp_plus_animad")


func make_money(difficulty : int):
	var on_money:int = 0
	on_money += (5*difficulty) + EffectProcessor.get_passive_bonus(BaseEffect.StatType.GOLD_BONUS)
	PlayerData.add_money(on_money)


func _update_money_display(new_amount):
	$Money/Label.text = str(new_amount)

func clear_hud():
	# 1. ล้างโหนด Icon ที่วาดค้างไว้บน HBoxContainer ทิ้งให้หมด
	for child in show_skill_hbox.get_children():
		child.queue_free()
	for child in show_skillactive_hbox.get_children():
		child.queue_free()
	
	# 2. ล้าง Dictionary ที่เก็บความสัมพันธ์ระหว่าง Skill กับ Node
	# ถ้าไม่ล้างอันนี้ เวลาได้สกิลเดิมในรอบใหม่ มันจะไปหาโหนดเก่าที่โดน queue_free ไปแล้วและ Error
	skill_ui_nodes.clear()
	active_skill_ui_nodes.clear()
