# EquipmentData.gd
extends Resource
class_name EquipmentData

@export var title: String
@export var desc: String 
@export var icon: Texture2D

# กำหนด Slot ที่ไอเทมนี้สามารถสวมใส่ได้
enum SlotType { HEAD, ACC, BODY, WEAPON,  LEG }
@export var slot: SlotType 

# ใช้ Resource BaseEffect ชุดเดียวกับที่คุณใช้ใน SkillData
# เพื่อให้ EffectProcessor คำนวณค่าพลังได้ทันที
@export var effects: Array[BaseEffect] = []
