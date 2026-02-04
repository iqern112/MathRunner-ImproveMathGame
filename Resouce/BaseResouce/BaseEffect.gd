# BaseEffect.gd
extends Resource
class_name BaseEffect

enum StatType { ATK, DEF, HP, ARMOR, EXP_BONUS, GOLD_BONUS, 
				DROP_RATE, DMG_CRI, ARMOR_CRI, TOXIN}

@export var type: StatType
@export var value: float
@export var chance: float = 1.0 # ค่าเริ่มต้นคือ 100% (1.0), ถ้า 40% ให้ใส่ 0.4
@export var is_percentage: bool = false
