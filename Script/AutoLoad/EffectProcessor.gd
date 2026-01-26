extends Node

func get_static_bonus(stat_type: BaseEffect.StatType) -> float:
	var total = 0.0
	for skill in PlayerData.own_skills.keys():
		var stack = PlayerData.own_skills[skill]
		for effect in skill.effects:
			# เช็คเฉพาะที่โอกาส (chance) >= 1.0 และประเภทตรงกัน
			if effect.type == stat_type and effect.chance >= 1.0:
				total += (effect.value * stack)
	return total

# --- 2. สำหรับค่าที่ต้อง "สุ่มดวง" (เช่น EXP Bonus 40%) ---
func get_chance_bonus(stat_type: BaseEffect.StatType) -> float:
	var total = 0.0
	for skill in PlayerData.own_skills.keys():
		var stack = PlayerData.own_skills[skill]
		for effect in skill.effects:
			# เช็คที่โอกาส (chance) < 1.0
			if effect.type == stat_type and effect.chance < 1.0:
				# ทอยลูกเต๋าครั้งเดียว
				if randf() <= effect.chance:
					total += (effect.value * stack)
	return total

# --- 3. ฟังก์ชันอำนวยความสะดวกสำหรับระบบต่อสู้ ---
func calculate_player_attack() -> int:
	var base_dmg = 5 + PlayerData.wish_bonus_atk # บวกพรเข้าไปด้วย
	return int(base_dmg + get_static_bonus(BaseEffect.StatType.ATK))

func calculate_player_block() -> int:
	var base_block = 5 + PlayerData.wish_bonus_def
	return int(base_block + get_static_bonus(BaseEffect.StatType.DEF))

func process_incoming_damage(raw_damage: int) -> int:
	var armor = get_static_bonus(BaseEffect.StatType.ARMOR)
	return int(max(1, raw_damage - armor))

func calculate_max_exp(base_max: int) -> int:
	# ดึงค่าโบนัสจากสกิลสถิต (Static) เช่น สกิล Learn
	# สมมติใน BaseEffect.StatType คุณตั้งชื่อว่า REDUCE_EXP
	var reduction = get_static_bonus(BaseEffect.StatType.REDUCE_EXP)
	
	# คำนวณค่า Max EXP ใหม่ แต่ต้องไม่ต่ำกว่า 1 (ป้องกันบั๊กเลเวลอัปไม่หยุด)
	return int(max(1, base_max - reduction))
