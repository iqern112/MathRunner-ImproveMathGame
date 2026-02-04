extends Control

@onready var numpad_button = $"../NumpadPanel/GridContainer/1"
@onready var desc_label = $Panel/DescriptionLabel
@onready var show_skill_hbox = $ShowSkill

var extra_base_reward = 0
var current_options: Array[SkillData] = [] 
var skill_ui_nodes: Dictionary = {} 

func _ready() -> void:
	var buttons = [$Panel/SkillButtonsContainer/Button, $Panel/SkillButtonsContainer/Button2, $Panel/SkillButtonsContainer/Button3]
	for i in range(buttons.size()):
		buttons[i].pressed.connect(_on_skill_selected.bind(i))
		buttons[i].focus_entered.connect(_show_desc.bind(i))
	GameEvents.level_up_signal.connect(select_skill)
	GameEvents.money_changed.connect(_update_money_display)
	GameEvents.add_skill.connect(_smart_update_hud)


func select_skill():
	if $Panel.visible: return
	
	var pool: Array[SkillData] = []
	# ดึงรายชื่อสกิลที่ผู้เล่นมีอยู่แล้วออกมา
	var owned_list = PlayerData.own_skills.keys()

	if owned_list.size() < 5:
		# กรณีสกิลยังไม่เต็ม 5 ช่อง: สุ่มจากสกิลทั้งหมดที่มีในเกม
		pool.assign(PlayerData.all_skills.duplicate())
	else:
		# กรณีสกิลเต็ม 5 ช่องแล้ว: สุ่มเฉพาะ 3 อย่างจาก 5 อย่างที่มี เพื่ออัปเกรดเลเวล
		pool.assign(owned_list)
		
	pool.shuffle()
	
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

	var player_anim = get_node_or_null("../../Player/AnimationPlayer")
	if player_anim:
		player_anim.play("exp_plus_animad")

	if not skill.is_passive:
		return

	var stack_count = PlayerData.own_skills[skill]
	if skill_ui_nodes.has(skill):
		skill_ui_nodes[skill].set_skill_info(skill.icon, stack_count)
	
	else:
		# 2. ถ้าเป็นสกิลใหม่ ให้หา "ช่องว่าง" ใน NinePatchRect1-5
		var current_skill_count = skill_ui_nodes.size()
		
		if current_skill_count < 5:
			# ดึงโหนดลูกลำดับที่ current_skill_count (0 ถึง 4)
			var target_node = show_skill_hbox.get_child(current_skill_count)
			
			# สมมติว่าโหนด NinePatchRect มีฟังก์ชัน set_skill_info หรือเราจะสั่งตรงๆ ก็ได้
			# ในที่นี้ถ้าคุณใช้โหนดธรรมดาที่ไม่มีสคริปต์ ให้เซ็ต Texture โดยตรง:
			target_node.texture = skill.icon
			# ถ้ามี Label บอกจำนวน Stack อยู่ข้างใน:
			target_node.get_node("Label").text = str(stack_count)
			
			# เก็บข้อมูลไว้ใน Dictionary ว่าสกิลนี้ใช้ Node ไหน
			skill_ui_nodes[skill] = target_node


func make_money(difficulty : int):
	var on_money:int = 0
	on_money += (5*difficulty) + EffectProcessor.get_total_bonus(BaseEffect.StatType.GOLD_BONUS)
	PlayerData.add_money(on_money)
	

func _update_money_display(new_amount):
	$Money/Label.text = str(new_amount)
