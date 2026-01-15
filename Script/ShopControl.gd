extends Control

@onready var numpad_button = $"../NumpadPanel/GridContainer/1"
@onready var desc_label = $Panel/DescriptionLabel
@onready var show_item_hbox = $ShowItem

@onready var reroll_butt: Button = $Panel/Reroll
@onready var back_butt: Button = $Panel/Back

@onready var player = $"../../Player"

const SHOP = preload("res://Scene/Shop.tscn")
const NEW_ITEM_SCENE = preload("res://Scene/ItemOnShow.tscn")

var shop_spawn_timer: Timer
var current_item_options: Array = []
var own_item: Dictionary = {}

var reroll_cost: int = 50
var reroll_count: int = 0
var is_shop_open: bool = false
var spawn_shop_on = 10

func _ready() -> void:
	#set_up_Shop()

	$Panel/ShopList/Button.pressed.connect(_on_buy_selected.bind(0))
	$Panel/ShopList/Button2.pressed.connect(_on_buy_selected.bind(1))
	$Panel/ShopList/Button3.pressed.connect(_on_buy_selected.bind(2))
	$Panel/ShopList/Button4.pressed.connect(_on_buy_selected.bind(3))
	$Panel/ShopList/Button5.pressed.connect(_on_buy_selected.bind(4))
	$Panel/ShopList/Button6.pressed.connect(_on_buy_selected.bind(5))

	$Panel/ShopList/Button.focus_entered.connect(_show_desc.bind(0))
	$Panel/ShopList/Button2.focus_entered.connect(_show_desc.bind(1))
	$Panel/ShopList/Button3.focus_entered.connect(_show_desc.bind(2))
	$Panel/ShopList/Button4.focus_entered.connect(_show_desc.bind(3))
	$Panel/ShopList/Button5.focus_entered.connect(_show_desc.bind(4))
	$Panel/ShopList/Button6.focus_entered.connect(_show_desc.bind(5))

	# ✅ ปุ่ม UI
	reroll_butt.pressed.connect(_on_reroll_pressed)
	reroll_butt.focus_entered.connect(_on_reroll_focus_entered)
	back_butt.pressed.connect(_on_back_pressed)
	back_butt.focus_entered.connect(_on_back_focus_entered)

	GameEvents.shop_opened.connect(_on_shop_selected)


func _on_back_focus_entered():
	desc_label.text = "Exit"

func _on_reroll_focus_entered():
	desc_label.text = "Reroll"

# -------------------------
# Spawn Shop
# -------------------------
#func set_up_Shop():
	#shop_spawn_timer = Timer.new()
	#shop_spawn_timer.process_mode = Node.PROCESS_MODE_ALWAYS # ✅ กัน pause ทำให้ Timer หยุด
	#add_child(shop_spawn_timer)
#
	#shop_spawn_timer.wait_time = spawn_shop_on
	#shop_spawn_timer.one_shot = true
	#shop_spawn_timer.timeout.connect(spawn_Shop)
	#shop_spawn_timer.start()
#
#func spawn_Shop():
	#if player:
		#var spawn_pos = player.global_position + Vector2(400, -47)
		#var instance = SHOP.instantiate()
		#instance.global_position = spawn_pos
		#$"../..".add_child(instance)
	#else:
		#print("Error: Player not found")


# -------------------------
# Shop UI Open/Close
# -------------------------
func _on_shop_selected():
	open_shop_ui()
	$"../Question/EquationContainer".visible = false

func open_shop_ui():
	is_shop_open = true
	reroll_count = 0
	fill_shop_items()

	get_tree().paused = true
	$Panel.visible = true
	$Panel.process_mode = Node.PROCESS_MODE_ALWAYS  # ✅ ให้ UI ยังรับ input ตอน pause

	$Panel/ShopList/Button.grab_focus()

	update_reroll_button_text()

func close_shop_ui():
	is_shop_open = false
	$Panel.visible = false
	get_tree().paused = false
	GameEvents.shop_closed.emit()
	if numpad_button:
		numpad_button.grab_focus()
	$"../Question/EquationContainer".visible = true


# -------------------------
# Fill Items (used by open + reroll)
# -------------------------
func fill_shop_items():
	var keys = GameEvents.data_items.keys()
	keys.shuffle()
	current_item_options = keys.slice(0, 6)

	_set_button_item($Panel/ShopList/Button, 0)
	_set_button_item($Panel/ShopList/Button2, 1)
	_set_button_item($Panel/ShopList/Button3, 2)
	_set_button_item($Panel/ShopList/Button4, 3)
	_set_button_item($Panel/ShopList/Button5, 4)
	_set_button_item($Panel/ShopList/Button6, 5)

	# เคลียร์คำอธิบาย
	desc_label.text = ""

func _set_button_item(btn: Node, index: int) -> void:
	var item_key = current_item_options[index]
	btn.get_node("ShopItem").texture = GameEvents.data_items[item_key]["icon"]
	btn.get_node("Price").text = GameEvents.data_items[item_key]["price"]


# -------------------------
# Reroll
# -------------------------
func _on_reroll_pressed():
	if not is_shop_open:
		return

	var cost = reroll_cost * (reroll_count + 1) # คำนวณราคาครั้งถัดไป
	
	# ตรวจสอบและตัดเงินผ่าน GameManager (หรือชื่อ Autoload ที่คุณตั้งไว้)
	if GameEvents.remove_money(cost):
		reroll_count += 1
		fill_shop_items()
		update_reroll_button_text()
		$Panel/Reroll.grab_focus()
	else:
		pass

func update_reroll_button_text():
	var next_cost = reroll_cost * (reroll_count + 1)
	$Panel/Reroll/Price.text = str(next_cost)


# -------------------------
# Back / Exit
# -------------------------
func _on_back_pressed():
	if not is_shop_open:
		return
	close_shop_ui()


# -------------------------
# Desc & Buy
# -------------------------
func _show_desc(index: int):
	var item_key = current_item_options[index]
	var data = GameEvents.data_items[item_key]
	desc_label.text = data["title"] + "\n" + data["desc"]

func _on_buy_selected(index: int):
	var item_key = current_item_options[index]
	var data = GameEvents.data_items[item_key]
	var price = int(data.get("price", 0))
	
	if GameEvents.remove_money(price):
		# เก็บเข้า GameEvents แทนตัวแปรในเครื่อง
		if GameEvents.own_item.has(item_key):
			GameEvents.own_item[item_key] += 1
		else:
			GameEvents.own_item[item_key] = 1
		update_item_hud_display()


func update_item_hud_display():
	# 1. ล้างไอคอนเก่าใน HBox ออกให้หมดก่อน
	for child in show_item_hbox.get_children():
		child.queue_free()

	# 2. วนลูปดึงข้อมูลไอเทมที่เราเป็นเจ้าของมาจาก GameEvents
	for item_key in GameEvents.own_item:
		var count = GameEvents.own_item[item_key]
		
		# ดึงข้อมูลตั้งต้น (เช่น icon) จาก data_items ที่อยู่ในสคริปต์นี้
		# (หรือถ้าคุณย้าย data_items ไป GameEvents แล้ว ให้เปลี่ยนเป็น GameEvents.data_items)
		var data = GameEvents.data_items[item_key] 

		# 3. สร้าง Instance ของไอคอนที่จะแสดงบน HUD
		var new_item = NEW_ITEM_SCENE.instantiate()
		show_item_hbox.add_child(new_item)
		
		# 4. ส่งข้อมูลไปแสดงผล (ต้องมีฟังก์ชัน set_item_info ใน NEW_ITEM_SCENE)
		if new_item.has_method("set_item_info"):
			new_item.set_item_info(data["icon"], count)
