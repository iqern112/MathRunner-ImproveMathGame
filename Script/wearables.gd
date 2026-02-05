extends Panel

# รายชื่อชื่อโหนดใน Scene ให้ตรงกับลำดับใน Enum (HEAD, BODY, WEAPON, ACC, LEG)
const SLOT_NODE_NAMES = ["HeadSlot", "AccSlot", "BodySlot", "WeaponSlot", "LegSlot"]
@onready var GlobalTooltip = $"../.."

func _ready():
	# 1. เชื่อมต่อสัญญาณเมื่อมีการเปลี่ยนไอเทม
	PlayerData.equipment_changed.connect(_on_equipment_updated)
	
	# 2. ตั้งค่าระบบ Focus และแสดงผลเริ่มต้น
	for i in range(SLOT_NODE_NAMES.size()):
		var slot_node = get_node_or_null(SLOT_NODE_NAMES[i])
		if slot_node:
			# เชื่อมต่อสัญญาณ Focus สำหรับ Global Tooltip
			slot_node.focus_entered.connect(_on_slot_focused.bind(i))
			slot_node.focus_exited.connect(func(): GlobalTooltip.hide_info())
			slot_node.mouse_entered.connect(_on_slot_focused.bind(i))
			slot_node.mouse_exited.connect(func(): GlobalTooltip.hide_info())
			
			# วาดไอเทมที่มีอยู่แล้วตอนเปิดหน้าจอขึ้นมาครั้งแรก
			_on_equipment_updated(i, PlayerData.equipped_items[i])

func _on_equipment_updated(slot_index: int, item: EquipmentData):
	var slot_name = SLOT_NODE_NAMES[slot_index]
	var slot_node = get_node_or_null(slot_name)
	if not slot_node: return
	
	var icon_rect = slot_node.get_node(slot_name) 
	var upgrade_label = slot_node.get_node_or_null("Label")
	
	if item:
		icon_rect.texture = item.icon
		icon_rect.show()
		
		if upgrade_label:
			var lvl = PlayerData.equipment_upgrades[slot_index]
			# ถ้าเลเวล 2 ขึ้นไป ให้โชว์เป็น +1, +2 (เลเวล - 1)
			if lvl > 1:
				upgrade_label.text = "+" + str(lvl - 1)
				upgrade_label.show()
			else:
				upgrade_label.hide() # เลเวล 1 ไม่โชว์ตัวเลข
	else:
		icon_rect.texture = null
		if upgrade_label: upgrade_label.hide()

# ฟังก์ชันแสดงคำอธิบายแบบ Global
func _on_slot_focused(slot_index: int):
	var item = PlayerData.equipped_items[slot_index]
	if item:
		# เรียกใช้ Global Tooltip ที่เป็น Autoload
		GlobalTooltip.show_info(item.title, item.desc)
	else:
		GlobalTooltip.show_info("ช่องว่าง", "ยังไม่ได้สวมใส่ไอเทม")
