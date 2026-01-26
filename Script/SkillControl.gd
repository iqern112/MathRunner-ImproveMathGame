extends Control

@onready var numpad_button = $"../NumpadPanel/GridContainer/1"
@onready var desc_label = $Panel/DescriptionLabel
@onready var show_skill_hbox = $ShowSkill

const SKILL_ITEM_SCENE = preload("res://Scene/SkillOnItem.tscn")

var extra_base_reward = 0

# --- การจัดการข้อมูล ---
#var all_skills: Array[SkillData] = [] 
var current_options: Array[SkillData] = [] 
#var own_skill: Dictionary = {} # { SkillData: int_stack }
var skill_ui_nodes: Dictionary = {} # { SkillData: UI_Node }

func _ready() -> void:
	# ต้องแน่ใจว่า Path นี้สะกดถูกต้องตามใน FileSystem ของคุณ
	#var skill_path = "res://Resouce/SkillData/"
	#load_all_skills_from_folder(skill_path)
	
	# เชื่อมต่อปุ่ม
	var buttons = [$Panel/SkillButtonsContainer/Button, $Panel/SkillButtonsContainer/Button2, $Panel/SkillButtonsContainer/Button3]
	for i in range(buttons.size()):
		buttons[i].pressed.connect(_on_skill_selected.bind(i))
		buttons[i].focus_entered.connect(_show_desc.bind(i))
	GameEvents.level_up_signal.connect(select_skill)
	GameEvents.money_changed.connect(_update_money_display)
	GameEvents.add_skill.connect(_smart_update_hud)

#func load_all_skills_from_folder(path: String):
	#var dir = DirAccess.open(path)
	#if dir:
		#dir.list_dir_begin()
		#var file_name = dir.get_next()
		#while file_name != "":
			#if file_name.ends_with(".tres") or file_name.ends_with(".res"):
				#var skill = load(path + file_name)
				#if skill is SkillData:
					#all_skills.append(skill)
			#file_name = dir.get_next()
		#print("Successfully loaded ", all_skills.size(), " skills.")
	#else:
		#print("CRITICAL ERROR: Cannot open path: ", path)

func select_skill():
	# --- ส่วนที่เพิ่มเพื่อป้องกันการเด้งซ้อน ---
	if $Panel.visible:
		print("Skill Panel is already open, skipping this trigger.")
		return
	# ---------------------------------------
	print("Level Up Signal Received!") # ถ้าคำนี้ไม่ขึ้น แสดงว่าสัญญาณส่งมาไม่ถึง
	
	if PlayerData.all_skills.is_empty(): 
		print("Warning: all_skills is empty, cannot show UI")
		return

	# สุ่มสกิล
	var pool = PlayerData.all_skills.duplicate()
	pool.shuffle()
	
	# ป้องกัน Error กรณีมีสกิลน้อยกว่า 3
	var pick_amount = min(3, pool.size())
	current_options = pool.slice(0, pick_amount)
	
	var buttons = [$Panel/SkillButtonsContainer/Button, $Panel/SkillButtonsContainer/Button2, $Panel/SkillButtonsContainer/Button3]
	
	# รีเซ็ตปุ่มทั้งหมด
	for b in buttons: b.visible = false
	
	# ตั้งค่าปุ่มตามสกิลที่สุ่มได้
	for i in range(current_options.size()):
		buttons[i].visible = true
		buttons[i].get_node("NinePatchRect").texture = current_options[i].icon
	
	# แสดงหน้าจอ
	get_tree().paused = true
	$Panel.visible = true
	buttons[0].grab_focus()
	
	if has_node("../Question/EquationContainer"):
		$"../Question/EquationContainer".visible = false

func _show_desc(index: int):
	if index < current_options.size():
		var skill = current_options[index]
		desc_label.text = skill.title + "\n" + skill.desc

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


func _smart_update_hud(skill: SkillData, _amount: int):
	# ดึงเลข Stack ปัจจุบันจาก PlayerData
	var stack_count = PlayerData.own_skills[skill]
	
	if skill_ui_nodes.has(skill):
		skill_ui_nodes[skill].set_skill_info(skill.icon, stack_count)
	else:
		var new_ui = SKILL_ITEM_SCENE.instantiate()
		show_skill_hbox.add_child(new_ui)
		new_ui.set_skill_info(skill.icon, stack_count)
		skill_ui_nodes[skill] = new_ui
		
	# เล่นแอนิเมชัน
	var player_anim = get_node_or_null("../../Player/AnimationPlayer")
	if player_anim:
		player_anim.play("exp_plus_animad")

func make_money(difficulty : int):
	var on_money:int = 0
	on_money += (5*difficulty) + extra_base_reward
	PlayerData.add_money(on_money)
	

func _update_money_display(new_amount):
	$Money/Label.text = str(new_amount)
