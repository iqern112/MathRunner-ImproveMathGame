# PlayerData.gd (Global Autoload)
extends Node

# --- 1. ข้อมูลสกิล (Skill Data) ---
var all_skills: Array[SkillData] = []
var own_skills: Dictionary = {} # { SkillData: stack_count }
var wish_bonus_atk = 0
var wish_bonus_def = 0
# --- 2. ข้อมูลเงิน (Economy) ---
var money: int = 0

# --- 3. ข้อมูลไอเทม (Inventory) ---
# เก็บเป็น { ItemData: quantity } เพื่อใช้ระบบ Resource เหมือนสกิล
var own_items: Dictionary = {} 

func _ready():
	load_all_resources()
	GameEvents.add_skill.connect(_on_skill_added)
	GameEvents.active_buff.connect(_on_buff_received)

func load_all_resources():
	# โหลดสกิล
	_scan_folder("res://Resouce/SkillData/", all_skills)
	print("PlayerData: Loaded ", all_skills.size(), " skills.")

func _on_buff_received(buff_name: String):
	if buff_name == "attack_incress":
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

# --- ระบบจัดการสกิล ---
func _on_skill_added(skill_resource: SkillData, amount: int):
	if own_skills.has(skill_resource):
		own_skills[skill_resource] += amount
	else:
		own_skills[skill_resource] = amount
	
	print("PlayerData updated: ", skill_resource.title, " now has ", own_skills[skill_resource], " stacks.")
