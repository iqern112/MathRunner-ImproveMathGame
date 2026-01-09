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

var data_items = {
	"sword": {"title": "Sword", "price": "200", "desc": "Increase damage by 3.", "icon": preload("res://Asset/ItemTres/sword.tres")},
	"shield": {"title": "Shield", "price": "120", "desc": "Provides 5 defense.", "icon": preload("res://Asset/ItemTres/shield.tres")},
	"armor": {"title": "Armor", "price": "200", "desc": "Reduce incoming damage by 1 each time.", "icon": preload("res://Asset/ItemTres/armor.tres")},
	"bow": {"title": "Bow", "price": "120", "desc": "Deal 5 free damage.", "icon": preload("res://Asset/ItemTres/archer.tres")},
	"drill": {"title": "Drill", "price": "150", "desc": "Deal 3 armor-piercing damage.", "icon": preload("res://Asset/ItemTres/drill.tres")},
	"potion": {"title": "Healing Potion", "price": "120", "desc": "Restore 5 HP.", "icon": preload("res://Asset/ItemTres/drug.tres")}
}

func _ready() -> void:
	set_up_Shop()

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
func set_up_Shop():
	shop_spawn_timer = Timer.new()
	shop_spawn_timer.process_mode = Node.PROCESS_MODE_ALWAYS # ✅ กัน pause ทำให้ Timer หยุด
	add_child(shop_spawn_timer)

	shop_spawn_timer.wait_time = 5.0
	shop_spawn_timer.one_shot = true
	shop_spawn_timer.timeout.connect(spawn_Shop)
	shop_spawn_timer.start()

func spawn_Shop():
	if player:
		var spawn_pos = player.global_position + Vector2(400, -47)
		var instance = SHOP.instantiate()
		instance.global_position = spawn_pos
		$"../..".add_child(instance)
	else:
		print("Error: Player not found")


# -------------------------
# Shop UI Open/Close
# -------------------------
func _on_shop_selected():
	open_shop_ui()

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

	if numpad_button:
		numpad_button.grab_focus()


# -------------------------
# Fill Items (used by open + reroll)
# -------------------------
func fill_shop_items():
	var keys = data_items.keys()
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
	btn.get_node("ShopItem").texture = data_items[item_key]["icon"]
	btn.get_node("Price").text = data_items[item_key]["price"]


# -------------------------
# Reroll
# -------------------------
func _on_reroll_pressed():
	if not is_shop_open:
		return

	# (ตัวอย่าง) คิดค่า reroll เพิ่มตามจำนวนครั้ง
	reroll_count += 1
	var cost = reroll_cost * reroll_count

	# ✅ ตรงนี้คุณต้องเชื่อมกับระบบเงินของคุณเอง
	# ตัวอย่างสมมติว่า player มีตัวแปร money
	if player and player.has_method("get_money") and player.has_method("add_money"):
		var money = player.get_money()
		if money < cost:
			desc_label.text = "Not enough money to reroll! Need $" + str(cost)
			return
		player.add_money(-cost)
	else:
		# ถ้ายังไม่มีระบบเงิน ก็ให้ reroll ได้ฟรีไปก่อน
		pass

	fill_shop_items()
	update_reroll_button_text()
	$Panel/ShopList/Button.grab_focus()

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
	var data = data_items[item_key]
	desc_label.text = data["title"] + "\n" + data["desc"]

func _on_buy_selected(index: int):
	var item_key = current_item_options[index]

	if own_item.has(item_key):
		own_item[item_key] += 1
	else:
		own_item[item_key] = 1

	apply_item_effects()
	update_item_hud_display()

	# ถ้าซื้อแล้วอยากปิดร้านทันทีให้เปิดบรรทัดนี้:
	# close_shop_ui()

func apply_item_effects(): 
	pass

func update_item_hud_display():
	for child in show_item_hbox.get_children():
		child.queue_free()

	for item_key in own_item:
		var count = own_item[item_key]
		var data = data_items[item_key]

		var new_item = NEW_ITEM_SCENE.instantiate()
		show_item_hbox.add_child(new_item)
		new_item.set_item_info(data["icon"], count)
