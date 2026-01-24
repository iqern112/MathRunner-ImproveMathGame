extends Control

@onready var numpad_button = $"../NumpadPanel/GridContainer/1"
@onready var desc_label = $Panel/DescriptionLabel
@onready var show_skill_hbox = $ShowSkill

const SKILL_ITEM_SCENE = preload("res://Scene/SkillOnItem.tscn")

var extra_base_reward = 0

var current_options = []
var own_skill = {}
var data_skills = {
	"lucky": {"title": "Lucky", "desc": "40% chance of a +1 EXP.", "icon": preload("res://Resouce/SkillIcon/lucky.tres")},
	"interest": {"title": "Interest", "desc": "Earn an extra +5 money.", "icon": preload("res://Resouce/SkillIcon/interest.tres")},
	"learn": {"title": "Learn", "desc": "Reduce MAX EXP -1.", "icon": preload("res://Resouce/SkillIcon/learn.tres")},
	"power": {"title": "Power", "desc": "Increase +2 damage.", "icon": preload("res://Resouce/SkillIcon/power.tres")},
	"shield": {"title": "Shield", "desc": "Gain +2 shield.", "icon": preload("res://Resouce/SkillIcon/shield.tres")},
	"armor": {"title": "Armor", "desc": "Reduce damage 1.", "icon": preload("res://Resouce/SkillIcon/armor.tres")},
}

func _ready() -> void:
	# 1. เชื่อมต่อสัญญาณไว้ล่วงหน้าด้วย "ลำดับของปุ่ม" (0, 1, 2)
	# ทำที่นี่ครั้งเดียว ไม่เกิด Error 'already connected' แน่นอน
	$Panel/SkillButtonsContainer/Button.pressed.connect(_on_skill_selected.bind(0))
	$Panel/SkillButtonsContainer/Button2.pressed.connect(_on_skill_selected.bind(1))
	$Panel/SkillButtonsContainer/Button3.pressed.connect(_on_skill_selected.bind(2))

	$Panel/SkillButtonsContainer/Button.focus_entered.connect(_show_desc.bind(0))
	$Panel/SkillButtonsContainer/Button2.focus_entered.connect(_show_desc.bind(1))
	$Panel/SkillButtonsContainer/Button3.focus_entered.connect(_show_desc.bind(2))
	
	#GameEvents.correct_answer_signal.connect(make_money)
	GameEvents.level_up_signal.connect(select_skill)
	GameEvents.money_changed.connect(_update_money_display)
	
	GameEvents.add_skill.connect(apply_skill_effects)
	
func select_skill():
	var keys = data_skills.keys()
	keys.shuffle() # สลับตำแหน่งข้อมูลในลิสต์
	current_options = keys.slice(0, 3)
	
	$Panel/SkillButtonsContainer/Button/NinePatchRect.texture = data_skills[current_options[0]]["icon"]
	$Panel/SkillButtonsContainer/Button2/NinePatchRect.texture = data_skills[current_options[1]]["icon"]
	$Panel/SkillButtonsContainer/Button3/NinePatchRect.texture = data_skills[current_options[2]]["icon"]
	
	get_tree().paused = true
	$Panel.visible = true
	$Panel/SkillButtonsContainer/Button.grab_focus()
	$"../Question/EquationContainer".visible = false

func _show_desc(index: int):
	# ฟังก์ชันนี้จะดึงชื่อสกิลล่าสุดจาก current_options ตามลำดับปุ่มที่ส่งมา
	var skill_key = current_options[index] 
	var data = data_skills[skill_key]
	desc_label.text = data["title"] + "\n" + data["desc"]

func _on_skill_selected(index: int):
	var skill_key = current_options[index]
	
	# เรียกใช้ฟังก์ชันกลางเพื่อจัดการเรื่อง Stack และ Effect (บวกเพิ่มทีละ 1 สำหรับเลเวลอัป)
	apply_skill_effects(skill_key, 1)
	
	# ปิดหน้าต่างและเล่นเกมต่อ
	$Panel.visible = false
	get_tree().paused = false
	if numpad_button: numpad_button.grab_focus()
	$"../Question/EquationContainer".visible = true

# แก้ไขฟังก์ชันนี้ให้รับ key และ amount (จำนวนที่ได้เพิ่ม)
func apply_skill_effects(key: String, amount: int = 1):
	# 1. จัดการเรื่อง Stack: ตรวจสอบว่ามีสกิลนี้อยู่หรือยัง
	if own_skill.has(key):
		own_skill[key] += amount # เพิ่มจำนวนตามที่ได้รับมา (จาก reward อาจเป็น 1-3)
	else:
		own_skill[key] = amount # ถ้ายังไม่มี ให้เริ่มตามจำนวนที่ได้
	
	# 2. ประมวลผลความสามารถของสกิลตาม Stack ใหม่
	match key:
		"lucky":
			var lucky_exp: int = own_skill.get("lucky", 0)
			GameEvents.skill_lucky.emit(lucky_exp)
		"interest":
			var interest_stack = own_skill.get("interest", 0)
			extra_base_reward = interest_stack * 5
		"learn":
			var reduce_exp = own_skill.get("learn", 0)
			GameEvents.skill_learn.emit(reduce_exp)
		"power":
			# ส่งค่า bonus ที่สะสมได้ทั้งหมดไปให้ระบบต่อสู้
			GameEvents.on_skill_recive.emit(key, 2 * amount) # สมมติว่าเพิ่มทีละ 2 ต่อ stack
		"shield":
			GameEvents.on_skill_recive.emit(key, 2 * amount)
		"armor":
			GameEvents.on_skill_recive.emit(key, 1 * amount)
			
	# 3. อัปเดตการแสดงผลไอคอนบนหน้าจอ
	update_skill_hud_display()
	
func update_skill_hud_display():
	# 1. ล้างไอคอนเก่าใน HBox ก่อนแสดงใหม่
	for child in show_skill_hbox.get_children():
		child.queue_free()
		
	# 2. วนลูปตามสกิลที่ผู้เล่นมีเก็บไว้ใน own_skill (Dictionary)
	for skill_key in own_skill:
		var count = own_skill[skill_key]
		var data = data_skills[skill_key]
		
		# 3. สร้าง Instance ของเทมเพลตขึ้นมา
		var new_item = SKILL_ITEM_SCENE.instantiate()
		
		# 4. เพิ่มเข้าไปใน HBoxContainer ก่อน
		show_skill_hbox.add_child(new_item)
		
		# 5. สั่งให้แสดงผล Icon และ เลข Stack
		# โดยส่ง Texture จาก data_skills และจำนวนจาก own_skill
		new_item.set_skill_info(data["icon"], count)
		$"../../Player/AnimationPlayer".play("exp_plus_animad")

func make_money(difficulty : int):
	var on_money:int = 0
	on_money += (5*difficulty) + extra_base_reward
	GameEvents.add_money(on_money)
	

func _update_money_display(new_amount):
	$Money/Label.text = str(new_amount)
