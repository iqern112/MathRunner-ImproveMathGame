class_name Room
extends Resource

enum Type {NOT_ASSIGNED, MONSTER, ELITE, BOSS, TREASURE, SHOP, CAMPFIRE, EVENT}

@export var type: Type
@export var row: int
@export var column: int
@export var position: Vector2
@export var next_rooms: Array[Room]
@export var selected: bool = false

func _to_string() -> String:
	# Type.keys() จะคืนค่า Array ["NOT_ASSIGNED", "MONSTER", ...]
	# แล้วเราก็ดึงตัวที่ index ตรงกับ type ของเราออกมา
	var type_name = Type.keys()[type] 
	return "%s (%s)" % [column, type_name]
