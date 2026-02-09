# PlayerData.gd (Global Autoload)
extends Node
signal refresh_hp
signal mana_changed(curr, m_mana)
signal active_skill_updated(skill: SkillData, stack: int)
signal passive_skill_updated(skill: SkillData, stack: int)
signal equipment_changed(slot, item)
enum Slot { HEAD, ACC, BODY, WEAPON,  LEG }

var equipped_items: Dictionary = {
	EquipmentData.SlotType.HEAD: null,
	EquipmentData.SlotType.ACC: null,
	EquipmentData.SlotType.BODY: null,
	EquipmentData.SlotType.WEAPON: null,
	EquipmentData.SlotType.LEG: null
}

var equipment_upgrades: Dictionary = {
	EquipmentData.SlotType.HEAD: 1, 
	EquipmentData.SlotType.ACC: 1,
	EquipmentData.SlotType.BODY: 1,
	EquipmentData.SlotType.WEAPON: 1,
	EquipmentData.SlotType.LEG: 1
}

var base_max_hp: int = 20
var current_hp: int = 20
var dodge: int = 0

var max_mana: int = 50
var current_mana: int = 50

var active_atk_buff: int = 0
var active_def_buff: int = 0

var wish_bonus_atk = 0
var wish_bonus_def = 0
var wish_hp_bonus = 0

var money: int = 0

var own_items: Dictionary = {} 

var all_skills: Array[SkillData] = []
var own_skills: Dictionary = {}

var all_equipments: Array[EquipmentData] = []

func _ready():
	load_all_resources()
	GameEvents.add_skill.connect(_on_skill_added)
	GameEvents.active_buff.connect(_on_buff_received)

func equip_item(item: EquipmentData):
	if not item: return
	
	var target_slot = item.slot
	
	# เช็คว่าไอเทมใหม่ที่ได้มา คืออันเดิมที่ใส่อยู่หรือไม่
	if equipped_items[target_slot] != null and equipped_items[target_slot].title == item.title:
		# กรณีเป็นไอเทมเดิม: เพิ่มระดับการอัปเกรด (+1)
		equipment_upgrades[target_slot] += 1
		print("ได้ของเดิม! อัปเกรดช่อง ", target_slot, " เป็นเลเวล ", equipment_upgrades[target_slot])
	else:
		# กรณีเป็นของใหม่: เปลี่ยนไอเทม และ รีเซ็ตเลเวลเป็น 1
		equipped_items[target_slot] = item
		equipment_upgrades[target_slot] = 1
		print("ได้ของใหม่! รีเซ็ตเลเวลช่อง ", target_slot, " เป็น 1")
	
	# แจ้งเตือน UI ให้วาดรูปและเลขใหม่
	equipment_changed.emit(target_slot, item)
	PlayerData.refresh_hp.emit()

func use_mana(final_amount: int) -> bool:
	if current_mana >= final_amount:
		current_mana -= final_amount
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
	_scan_folder("res://Resouce/Equipment/", all_equipments)
	print("load")

func _on_buff_received(buff_name: String):
	if buff_name == "hp_incress":
		current_hp += 8
		wish_hp_bonus += 8
		PlayerData.refresh_hp.emit()
	elif buff_name == "attack_incress":
		wish_bonus_atk += 3
	elif buff_name == "block_incress":
		wish_bonus_def += 3

#func _scan_folder(path: String, target_array: Array):
	#var dir = DirAccess.open(path)
	#if dir:
		#dir.list_dir_begin()
		#var file_name = dir.get_next()
		#while file_name != "":
			#if file_name.ends_with(".tres"):
				#var res = load(path + file_name)
				#target_array.append(res)
			#file_name = dir.get_next()

func _scan_folder(path: String, target_array: Array):
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				# หลัง Export ไฟล์ .tres อาจถูกเปลี่ยนเป็น .tres.remap
				if file_name.ends_with(".tres") or file_name.ends_with(".tres.remap"):
					# ตัด .remap ออกเพื่อให้โหลดได้ปกติ
					var clean_path = path + file_name.replace(".remap", "")
					var res = load(clean_path)
					if res:
						target_array.append(res)
			file_name = dir.get_next()
		print("PlayerData: Loaded from ", path, " count: ", target_array.size())

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

# PlayerData.gd

func reset_data():
	# รีเซ็ต Stat พื้นฐาน
	current_hp = base_max_hp
	current_mana = max_mana
	money = 0
	dodge = 0
	
	# ล้างบัฟและโบนัสสะสม
	wish_bonus_atk = 0
	wish_bonus_def = 0
	wish_hp_bonus = 0
	active_atk_buff = 0
	active_def_buff = 0
	
	# ล้างไอเทมและเลเวลอัปเกรด
	for slot in equipped_items.keys():
		equipped_items[slot] = null
		equipment_upgrades[slot] = 1
	
	# ล้างรายการสกิลที่เคยมี (Dict จะว่างเปล่าเหมือนเริ่มเกมใหม่)
	own_skills.clear()
	own_items.clear()
	
	# ส่งสัญญาณอัปเดต UI ทันที
	refresh_hp.emit()
	mana_changed.emit(current_mana, max_mana)
	GameEvents.money_changed.emit(money)
