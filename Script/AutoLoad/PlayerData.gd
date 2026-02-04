# PlayerData.gd (Global Autoload)
extends Node
signal refresh_hp
signal mana_changed(curr, m_mana)
signal active_skill_updated(skill: SkillData, stack: int)
signal passive_skill_updated(skill: SkillData, stack: int)

var base_max_hp: int = 20
var current_hp: int = 20

var max_mana: int = 50
var current_mana: int = 50

# ตัวแปรพักค่า Buff (Active Skill)
var active_atk_buff: int = 0
var active_def_buff: int = 0

# --- 1. ข้อมูลสกิล (Skill Data) ---
var all_skills: Array[SkillData] = []
var own_skills: Dictionary = {} # { SkillData: stack_count }
var wish_bonus_atk = 0
var wish_bonus_def = 0
var wish_hp_bonus = 0
# --- 2. ข้อมูลเงิน (Economy) ---
var money: int = 0

# --- 3. ข้อมูลไอเทม (Inventory) ---
# เก็บเป็น { ItemData: quantity } เพื่อใช้ระบบ Resource เหมือนสกิล
var own_items: Dictionary = {} 

func _ready():
	load_all_resources()
	GameEvents.add_skill.connect(_on_skill_added)
	GameEvents.active_buff.connect(_on_buff_received)

func use_mana(amount: int) -> bool:
	if current_mana >= amount:
		current_mana -= amount
		mana_changed.emit(current_mana, max_mana)
		return true
	return false

func recover_mana(amount: int):
	current_mana = clampi(current_mana + amount, 0, max_mana)
	mana_changed.emit(current_mana, max_mana)

func load_all_resources():
	# โหลดสกิล
	_scan_folder("res://Resouce/SkillData/Passive/", all_skills)
	_scan_folder("res://Resouce/SkillData/Active/", all_skills)
	print("PlayerData: Loaded ", all_skills.size(), " skills.")

func _on_buff_received(buff_name: String):
	if buff_name == "hp_incress":
		current_hp += 8
		wish_hp_bonus += 8
		PlayerData.refresh_hp.emit()
	elif buff_name == "attack_incress":
		wish_bonus_atk += 3
	elif buff_name == "block_incress":
		wish_bonus_def += 3

func _scan_folder(path: String, target_array: Array):
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var res = load(path + file_name)
				target_array.append(res)
			file_name = dir.get_next()

# --- ระบบจัดการเงิน ---
func add_money(amount: int):
	money += amount
	GameEvents.money_changed.emit(money)

func remove_money(amount: int) -> bool:
	if money >= amount:
		money -= amount
		GameEvents.money_changed.emit(money)
		return true
	return false

func _on_skill_added(skill_resource: SkillData, amount: int):
	# อัปเดตที่เดียวจบ
	if own_skills.has(skill_resource):
		own_skills[skill_resource] += amount
	else:
		own_skills[skill_resource] = amount

	var current_stack = own_skills[skill_resource]

	# ส่งสัญญาณแยกเพื่อให้ UI (HUD) รู้ว่าต้องวาดที่แถวไหน
	if skill_resource.is_passive:
		passive_skill_updated.emit(skill_resource, current_stack)
	else:
		active_skill_updated.emit(skill_resource, current_stack)

	# จัดการ HP (เหมือนเดิม)
	for effect in skill_resource.effects:
		if effect.type == BaseEffect.StatType.HP:
			current_hp += int(effect.value * amount)
			PlayerData.refresh_hp.emit()
