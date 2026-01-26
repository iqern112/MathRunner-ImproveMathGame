# SkillData.gd (ใช้ทั้ง Active และ Passive)
extends Resource
class_name SkillData
@export var title: String
@export var icon: Texture2D
@export var desc: String
@export var is_passive: bool
@export var mana_cost: int
@export var effects: Array[BaseEffect]
