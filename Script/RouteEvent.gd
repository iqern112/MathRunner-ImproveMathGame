extends Control

# อ้างอิงโหนดที่คุณเตรียมไว้แล้ว
@onready var reward_rect1 = $RewardPanal/RewardContainer/Button/NinePatchRect
@onready var reward_rect2 = $RewardPanal/RewardContainer/Button2/NinePatchRect
@onready var stack_label1 = $RewardPanal/RewardContainer/Button/NinePatchRect/Label2
@onready var stack_label2 = $RewardPanal/RewardContainer/Button2/NinePatchRect/Label2

# อ้างอิงปุ่ม
@onready var btn1 = $RewardPanal/RewardContainer/Button
@onready var btn2 = $RewardPanal/RewardContainer/Button2

var data_skills = {
	"lucky": {"title": "Lucky", "desc": "40% chance of a +1 EXP.", "icon": preload("res://Resouce/SkillIcon/lucky.tres")},
	"interest": {"title": "Interest", "desc": "Earn an extra +5 money.", "icon": preload("res://Resouce/SkillIcon/interest.tres")},
	"learn": {"title": "Learn", "desc": "Reduce MAX EXP -1.", "icon": preload("res://Resouce/SkillIcon/learn.tres")},
	"power": {"title": "Power", "desc": "Increase +2 damage.", "icon": preload("res://Resouce/SkillIcon/power.tres")},
	"shield": {"title": "Shield", "desc": "Gain +2 shield.", "icon": preload("res://Resouce/SkillIcon/shield.tres")},
	"armor": {"title": "Armor", "desc": "Reduce damage 1.", "icon": preload("res://Resouce/SkillIcon/armor.tres")},
}

var monney = {
	"gold": {
		"title": "Gold", 
		"desc": "Receive gold coins for shopping.", 
		"icon": preload("res://Resouce/SkillIcon/Gold.tres")
	}
}

func _ready() -> void:
	GameEvents.reward.connect(mons_die)
	btn1.pressed.connect(_on_reward_selected.bind(btn1))
	btn2.pressed.connect(_on_reward_selected.bind(btn2))


func mons_die():
	$RewardPanal.visible = true
	GameEvents.open_close_nam.emit("close")
	# ตั้งค่าปุ่ม 1 (Skill) โดยส่งโหนดที่เกี่ยวข้องเข้าไป
	setup_skill_reward(reward_rect1, stack_label1, btn1)
	
	# ตั้งค่าปุ่ม 2 (Gold)
	setup_gold_reward(reward_rect2, stack_label2, btn2)
	
	btn1.grab_focus()

func setup_skill_reward(rect: NinePatchRect, stack: Label, btn: Button):
	var selected_key = data_skills.keys().pick_random()
	var skill_data = data_skills[selected_key]
	var count = randi_range(1, 3)
	
	# กำหนดค่าลงโหนดโดยตรง (Direct Property Access)
	rect.texture = skill_data["icon"]
	stack.text = skill_data["title"]
	
	# เก็บ Metadata เหมือนเดิมเพื่อให้ระบบเลือกรางวัลทำงานได้
	btn.set_meta("reward_type", "SKILL")
	btn.set_meta("skill_key", selected_key)
	btn.set_meta("count", count)
	btn.tooltip_text = skill_data["desc"]

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
	
	if type == "SKILL":
		var key = btn.get_meta("skill_key")
		var count = btn.get_meta("count")
		print("Get Skill: ", key, " x", count)
		# GameEvents.add_skill.emit(key, count)
	elif type == "GOLD":
		var amount = btn.get_meta("amount")
		GameEvents.add_money(amount)
		print("Get Gold: ", amount)
	
	$RewardPanal.visible = false
	GameEvents.open_map.emit()
