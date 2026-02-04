extends Node

# ฟังก์ชันกลางสำหรับดึงค่า Bonus (รองรับทั้ง Flat และ Percentage)
func get_total_bonus(stat_type: BaseEffect.StatType) -> float:
	var total = 0.0
	for skill in PlayerData.own_skills.keys():
		var stack = PlayerData.own_skills[skill]
		for effect in skill.effects:
			if effect.type == stat_type:
				total += (effect.value * stack)
	return total


# --- 3. ฟังก์ชันอำนวยความสะดวกสำหรับระบบต่อสู้ ---
func calculate_player_attack(is_preview: bool = false) -> int:
	var base_dmg = 5 + PlayerData.wish_bonus_atk
	var total_dmg = base_dmg + get_total_bonus(BaseEffect.StatType.ATK)
	
	total_dmg += PlayerData.active_atk_buff
	
	# ถ้าไม่ใช่แค่การเรียกดู (คือการโจมตีจริง) ให้ล้างบัฟ
	if not is_preview:
		PlayerData.active_atk_buff = 0
	
	# Logic Crit (Preview ก็ควรเห็นโอกาสคริแบบ Average หรือไม่ต้องคำนวณ RNG ใน Preview)
	var crit_chance = 0.05 + (get_total_bonus(BaseEffect.StatType.DMG_CRI) / 100.0)
	
	# ใน Preview เราอาจจะไม่สุ่ม RNG เพื่อให้เลขบนปุ่มนิ่ง
	if not is_preview and randf() <= crit_chance:
		return int(total_dmg * 2.0)
		
	return int(total_dmg)

func calculate_player_block(is_preview: bool = false) -> int:
	var base_block = 5 + PlayerData.wish_bonus_def
	var total_block = base_block + get_total_bonus(BaseEffect.StatType.DEF)
	
	total_block += PlayerData.active_def_buff
	
	if not is_preview:
		PlayerData.active_def_buff = 0
	
	var armor_crit_chance = 0.05 + (get_total_bonus(BaseEffect.StatType.ARMOR_CRI) / 100.0)
	if not is_preview and randf() <= armor_crit_chance:
		return int(total_block * 2.0)
		
	return int(total_block)

func process_incoming_damage(raw_damage: int) -> int:
	var armor = get_total_bonus(BaseEffect.StatType.ARMOR)
	return int(max(1, raw_damage - armor))


func calculate_max_hp(base_hp: int) -> int:
	return base_hp + int(get_total_bonus(BaseEffect.StatType.HP)) + PlayerData.wish_hp_bonus
