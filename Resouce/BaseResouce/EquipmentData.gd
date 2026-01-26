# EquipmentData.gd
extends Resource
class_name EquipmentData
enum Slot { HEAD, CHEST, LEGS, R_ARM, L_ARM }
@export var name: String
@export var slot: Slot
@export var effects: Array[BaseEffect]
