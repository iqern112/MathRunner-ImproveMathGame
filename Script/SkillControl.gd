extends Control

@onready var numpad_button = $"../NumpadPanel/GridContainer/1"
@onready var desc_label = $Panel/DescriptionLabel
@onready var show_skill_hbox = $ShowSkill
@onready var show_skillactive_hbox = $ShowActive

var extra_base_reward = 0
var current_options: Array[SkillData] = [] 
var skill_ui_nodes: Dictionary = {} 
var active_skill_ui_nodes: Dictionary = {} 

func _ready() -> void:
	var all_buttons = $Panel/SkillButtonsContainer.get_children()
	for i in range(all_buttons.size()):
		var btn = all_buttons[i]
		btn.pressed.connect(_on_skill_selected.bind(i))
		btn.focus_entered.connect(_show_desc.bind(i))
	GameEvents.level_up_signal.connect(select_skill)
	GameEvents.money_changed.connect(_update_money_display)
	GameEvents.add_skill.connect(_play_get_skill_anim)
	PlayerData.passive_skill_updated.connect(_update_passive_ui)
	PlayerData.active_skill_updated.connect(_update_active_ui)

func _update_passive_ui(skill: SkillData, stack: int):
	_display_on_hud(skill, stack, skill_ui_nodes, show_skill_hbox)

# สำหรับแสดง Active (แถวล่าง)
func _update_active_ui(skill: SkillData, stack: int):
	_display_on_hud(skill, stack, active_skill_ui_nodes, show_skillactive_hbox)

func select_skill():
	if $Panel.visible: return
	
	# 1. คำนวณจำนวนช่องพื้นฐาน
	var pick_amount = 3 
	var luck_percent = EffectProcessor.get_passive_bonus(BaseEffect.StatType.DROP_RATE) # เช่น 5.0, 10.0
	
	# 2. สุ่มโอกาสเพิ่มช่องที่ 4
	if randf() <= (luck_percent / 100.0):
		pick_amount += 1
		print("Luck ทำงาน! เพิ่มช่องเลือกสกิลเป็น 4 ช่อง")
		
		# 3. ถ้าสุ่มได้ช่องที่ 4 แล้ว ให้สุ่มโอกาสได้ช่องที่ 5 ต่อ (หรือจะใช้เงื่อนไขอื่นก็ได้)
		# ในที่นี้ใช้โอกาสเดียวกัน ถ้า Luck เยอะ ก็มีสิทธิ์ลุ้นถึง 5 ช่อง
		if randf() <= (luck_percent / 100.0):
			pick_amount += 1
			print("ดวงดีสุดๆ! เพิ่มช่องเลือกสกิลเป็น 5 ช่อง")

	# --- กระบวนการสุ่มสกิลจาก Pool ---
	var pool: Array[SkillData] = []
	var owned_list = PlayerData.own_skills.keys()

	if owned_list.size() < 5:
		pool.assign(PlayerData.all_skills.duplicate())
	else:
		pool.assign(owned_list)
		
	pool.shuffle()
	
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
