extends Node

func get_passive_bonus(stat_type: BaseEffect.StatType) -> float:
	var total = 0.0
	for skill in PlayerData.own_skills.keys():
		# สำคัญ: ต้องเป็น Passive เท่านั้นถึงจะนับเป็นโบนัสติดตัวถาวร
		if skill.is_passive:
			var stack = PlayerData.own_skills[skill]
			for effect in skill.effects:
				if effect.type == stat_type:
					total += (effect.value * stack)
	return total

func calculate_player_attack(is_preview: bool = false) -> int:
	var base_dmg = 5 + PlayerData.wish_bonus_atk
	var passive_bonus = get_passive_bonus(BaseEffect.StatType.ATK)
	var active_bonus = PlayerData.active_atk_buff
	
	var total_dmg = base_dmg + passive_bonus + active_bonus
	
	if not is_preview:
		PlayerData.active_atk_buff = 0 
		
	return int(total_dmg)

func calculate_player_block(is_preview: bool = false) -> int:
	var base_block = 5 + PlayerData.wish_bonus_def
	# แก้จาก get_total_bonus เป็น get_passive_bonus
	var passive_def = get_passive_bonus(BaseEffect.StatType.DEF)
	var active_def = PlayerData.active_def_buff
	
	var total_block = base_block + passive_def + active_def
	
	if not is_preview:
		PlayerData.active_def_buff = 0
	
	# คำนวณโอกาสป้องกันคริติคอล (ถ้ามี)
	var armor_crit_chance = 0.05 + (get_passive_bonus(BaseEffect.StatType.ARMOR_CRI) / 100.0)
	if not is_preview and randf() <= armor_crit_chance:
		return int(total_block * 2.0)
		
	return int(total_block)

func process_incoming_damage(raw_damage: int) -> int:
	# ใช้เฉพาะ Armor จาก Passive
	var armor = get_passive_bonus(BaseEffect.StatType.ARMOR)
	return int(max(1, raw_damage - armor))

func calculate_max_hp(base_hp: int) -> int:
	# ใช้โบนัส HP จาก Passive + โบนัสพิเศษจากอีเวนต์
	return base_hp + int(get_passive_bonus(BaseEffect.StatType.HP)) + PlayerData.wish_hp_bonus


func apply_active_skill_effect(skill: SkillData):
	# ดึงจำนวนเลเวล (stack) ของสกิลนั้นๆ
	var stack = PlayerData.own_skills.get(skill, 1)
	
	for effect in skill.effects:
		match effect.type:
			BaseEffect.StatType.ATK:
				PlayerData.active_atk_buff += (effect.value * stack)
			BaseEffect.StatType.DEF:
				PlayerData.active_def_buff += (effect.value * stack)
			BaseEffect.StatType.HP:
				# ถ้าเป็น Active Skill ฮีลเลือด ให้ฮีลทันที
				PlayerData.current_hp = clampi(PlayerData.current_hp + int(effect.value * stack), 0, calculate_max_hp(PlayerData.base_max_hp))
				PlayerData.refresh_hp.emit()
