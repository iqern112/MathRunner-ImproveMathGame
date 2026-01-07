extends Node2D

@onready var container = $CanvasLayer/EquationContainer
@onready var total_time_label = $CanvasLayer/TotalTimeLabel
@onready var numpad = $CanvasLayer/NumpadPanel
@onready var level_bar = $CanvasLayer/LevelBar
@onready var level_label = $CanvasLayer/LevelLabel # (ถ้ามี Label โชว์เลขเวล)
@onready var streak_label = $CanvasLayer/StreakLabel # สร้าง Label ไว้โชว์คอมโบ
@onready var money_label = $CanvasLayer/MoneyLabel   # สร้าง Label ไว้โชว์เงิน
@onready var LevelBarLabel = $CanvasLayer/LevelBar/LevelBarLabel
@onready var skill_buttons_container = $CanvasLayer/LevelUpPanel/VBoxContainer/SkillButtonsContainer
@onready var shop_panel = $CanvasLayer/ShopPanel
@onready var shop_timer = $ShopTimer
@onready var shop_buttons = $CanvasLayer/ShopPanel/VBoxContainer/ShopButtons
@onready var shield_label = $CanvasLayer/Inventory/VBoxContainer/ShieldCountLabel
@onready var lucky_label = $CanvasLayer/Inventory/VBoxContainer/LuckyStreakLabel
@onready var interest_label = $CanvasLayer/Inventory/VBoxContainer/InterestLabel
@onready var ActionSelect = $CanvasLayer/ActionPanel/VBoxContainer/ActionSelect
@onready var boss_action_timer = $BossActionTimer # Timer ที่นับถอยหลังโจมตีเราตลอดเวลา
@onready var boss_node = $Boss
@onready var action_panel = $CanvasLayer/ActionPanel
# ตัวแปรควบคุมเวลาและสถานะ
var boss_battle_triggered = false
const BOSS_SPAWN_TIME = 10.0 # 2 นาที
var is_boss_mode = false
var boss_max_hp = 50
var boss_hp = 30
var boss_shields = 0
var player_shields = 0  # จำนวนโล่ที่สะสมไว้ (Stack)
var player_hp = 5
var player_max_hp = 5
var boss_next_damage = 0  # สุ่มพลังโจมตีบอสในรอบนั้น
var boss_next_block = 0   # สุ่มการเพิ่มโล่บอสในรอบนั้น
var boss_action = "" # "ATTACK" หรือ "BLOCK"
@onready var player_hp_bar = $CharacterBody2D/PlayerHp
@onready var player_hp_label = $CharacterBody2D/PlayerHp/PlayerHpLabel
@onready var player_shield_label = $CharacterBody2D/Shield

@onready var boss_hp_bar = $Boss/BossHp
@onready var boss_hp_label = $Boss/BossHp/BossHpLabel
@onready var boss_hint_label = $Boss/Hint
@onready var boss_shield_label = $Boss/Shield

var lucky_chance = 0.0       # เริ่มที่ 0% (0.1 = 10%)
var extra_base_reward = 0    # สะสมเงินฐานเพิ่มขึ้นเรื่อยๆ
var exp_reduction_count = 0  # นับจำนวนครั้งที่ลด Max EXP

var shield_count = 0  # จำนวนโล่ที่มี (ซื้อซ้ำได้)

var streak = 0
var money = 0
var current_exp = 0
var current_level = 1
var difficulty = 0.5
var correct_answers = [] 
var input_fields = []    
var elapsed_time = 0.0 # เวลาสะสมเป็นวินาที
var is_game_over = false

func _process(delta):
	if not is_game_over:
		elapsed_time += delta
		update_time_display()
		update_level_ui()
		update_exp()
		update_inventory_ui()
		
		if is_boss_mode:
			update_battle_ui()
		else:
			# อัปเดตเฉพาะ UI ผู้เล่นปกติ
			update_player_stats_ui()
		
		if elapsed_time >= BOSS_SPAWN_TIME and not boss_battle_triggered:
			boss_battle_triggered = true
			start_boss_battle()
			print("start_boss_battle")

func _ready() -> void:
	# สุ่มเมล็ดพันธุ์ (Seed) เพื่อให้การสุ่มแต่ละครั้งไม่เหมือนเดิม
	# ดึงโฟกัสมาที่หน้าต่างเกมเพื่อให้รับ Input ได้ทันที
	await get_tree().process_frame # รอให้ Engine เตรียมตัว 1 เฟรม
	focus_numpad()
	randomize() 
	numpad.digit_pressed.connect(_on_numpad_digit)
	numpad.delete_pressed.connect(_on_numpad_delete)
	numpad.submit_pressed.connect(check_all_answers)
	# เชื่อมสัญญาณจาก Timer
	shop_timer.timeout.connect(_on_shop_timer_timeout)
	# เชื่อมสัญญาณปุ่มในร้านค้า
	for btn in shop_buttons.get_children():
		btn.pressed.connect(_on_buy_item.bind(btn.name))
	# ปุ่มปิดร้าน
	$CanvasLayer/ShopPanel/VBoxContainer/CloseButton.pressed.connect(_on_close_shop)
	
	player_hp_bar.max_value = player_max_hp
	player_hp_bar.value = player_hp
	boss_hp_bar.max_value = boss_max_hp
	boss_hp_bar.value = boss_hp
		
		# ซ่อน UI บอสไว้ก่อนจนกว่าจะถึงเวลา
	boss_node.visible = false
		
	# เชื่อมต่อปุ่ม Action (ถ้ายังไม่ได้เชื่อมใน Editor)
	ActionSelect.get_node("AttackButton").pressed.connect(_on_action_selected.bind("ATTACK"))
	ActionSelect.get_node("Block").pressed.connect(_on_action_selected.bind("SHIELD"))
		
		# เชื่อมต่อสัญญาณ Timer บอส
	boss_action_timer.timeout.connect(_on_boss_action_timer_timeout)
	
	generate_dynamic_question()

# แยกฟังก์ชันอัปเดตฝั่งผู้เล่นออกมาให้เรียกใช้ได้ตลอด
func update_player_stats_ui():
	player_hp_bar.value = player_hp
	player_hp_label.text = "HP: %d/%d" % [player_hp, player_max_hp]
	player_shield_label.text = "🛡️ %d" % player_shields

func start_boss_battle():
	print("2")
	is_boss_mode = true
	boss_hp = 50
	boss_shields = 0
	boss_node.visible = true
	$Dino.current_speed = 0
	$Dino.visible = false 
	$Dino.set_physics_process(false)
	$CharacterBody2D.speed = 0
	boss_node.global_position.x = $CharacterBody2D.global_position.x + 400
	#boss_node.global_position.y = $CharacterBody2D.global_position.y - 400
	# ตั้งค่า HP Bar 
	boss_hp_bar.max_value = boss_hp
	boss_hp_bar.value = boss_hp
	
	prepare_boss_next_move()
	show_result("!!! BOSS APPEARED !!!")

func prepare_boss_next_move():
	if not is_boss_mode: return
	
	# สุ่มแอคชั่นระหว่าง ATTACK หรือ BLOCK
	var actions = ["ATTACK", "BLOCK"]
	boss_action = actions[randi() % actions.size()]
	
	# 1. สุ่มเวลาทำแอคชั่น 3 - 10 วินาที ตามที่ต้องการ
	boss_action_timer.wait_time = randf_range(3.0, 10.0)
	boss_action_timer.start()
	
	# 2. สุ่มค่าพลัง (3-5) ไว้ล่วงหน้าเพื่อโชว์ Hint
	if boss_action == "ATTACK":
		boss_next_damage = randi_range(3, 5)
		boss_hint_label.text = "ATTACK:%d" % boss_next_damage
		boss_hint_label.modulate = Color.RED
	else:
		boss_next_block = randi_range(3, 5)
		boss_hint_label.text = "BLOCK:+%d" % boss_next_block
		boss_hint_label.modulate = Color.CYAN

func _on_boss_action_timer_timeout():
	if not is_boss_mode: return
	
	if boss_action == "ATTACK":
		# 4. ระบบหักล้างโล่ก่อนเข้า HP
		var damage_to_deal = boss_next_damage
		
		if player_shields > 0:
			if player_shields >= damage_to_deal:
				player_shields -= damage_to_deal
				damage_to_deal = 0
				show_result("BLOCKED ALL!")
			else:
				damage_to_deal -= player_shields
				player_shields = 0
				show_result("SHIELD BROKEN!")
		
		if damage_to_deal > 0:
			player_hp -= damage_to_deal
			show_result("HIT: -%d HP" % damage_to_deal)
			
		if player_hp <= 0:
			# เรียกฟังก์ชันตาย/GameOver ของคุณ
			
			show_result("GAME OVER")
			$CanvasLayer/GameOverUI.game_over()
			
	elif boss_action == "BLOCK":
		boss_shields += boss_next_block
		show_result("BOSS GAINED SHIELD!")

	# เริ่มรอบถัดไปทันที
	prepare_boss_next_move()


func _on_action_selected(choice):
	action_panel.visible = false 
	boss_action_timer.paused = false
	# 3. ผู้เล่นโจมตี 5 หรือ เพิ่มโล่ 5
	if choice == "ATTACK":
		var p_damage = 5
		# 4. หักล้างโล่บอสก่อนเข้า HP บอส
		if boss_shields > 0:
			if boss_shields >= p_damage:
				boss_shields -= p_damage
				p_damage = 0
				show_result("BOSS BLOCKED!")
			else:
				p_damage -= boss_shields
				boss_shields = 0
				show_result("BOSS SHIELD BROKEN!")
		
		if p_damage > 0:
			boss_hp -= p_damage
			show_result("BOSS HIT: -5")
			
		if boss_hp <= 0:
			win_boss_battle()
			return # ออกจากฟังก์ชันทันที
			
	elif choice == "SHIELD":
		player_shields += 5
		show_result("SHIELD STACKED: +5")

	# เจนโจทย์ใหม่ให้ผู้เล่นทำต่อทันที
	generate_dynamic_question()
	focus_numpad()


func win_boss_battle():
	is_boss_mode = false
	boss_node.visible = false
	boss_action_timer.stop()
	show_result("BOSS DEFEATED!")

func update_battle_ui():
	# อัปเดตฝั่งบอส
	boss_hp_bar.value = boss_hp
	boss_hp_label.text = "%d / %d" % [boss_hp, boss_max_hp]
	boss_shield_label.text = "🛡️ " + str(boss_shields)
	# แสดงเวลาที่เหลือก่อนบอสลงมือ
	$Boss/CountTime.text = " %.1d" % boss_action_timer.time_left
	
	# อัปเดตฝั่งผู้เล่น
	player_hp_bar.value = player_hp
	player_hp_label.text = "%d / %d" % [player_hp, player_max_hp]
	player_shield_label.text = "🛡️ " + str(player_shields)

func open_action_menu():
	action_panel.visible = true
	boss_action_timer.paused = true
	# โฟกัสไปที่ปุ่มแรก (เช่น ปุ่มโจมตี) เพื่อให้กด Shift เลือกได้ทันที
	ActionSelect.get_node("AttackButton").grab_focus()

func update_inventory_ui():
	# แสดงจำนวนโล่
	if shield_count > 0:
		shield_label.text = "🛡️ Shields: " + str(shield_count)
		shield_label.visible = true
	else:
		shield_label.visible = false # ซ่อนถ้าไม่มีของ
	
	# แสดงโอกาส Lucky Streak (ถ้ามี)
	if lucky_chance > 0:
		lucky_label.text = "🍀 Lucky: " + str(int(lucky_chance * 100)) + "%"
		lucky_label.visible = true
	else:
		lucky_label.visible = false
		
	# แสดงโบนัสเงินฐาน
	if extra_base_reward > 0:
		interest_label.text = "💰 Bonus: +$" + str(extra_base_reward)
		interest_label.visible = true
	else:
		interest_label.visible = false

func _on_close_shop():
	shop_panel.visible = false
	get_tree().paused = false
	# อย่าลืมคืน Focus กลับไปที่ Numpad
	focus_numpad()

func focus_numpad():
	$CanvasLayer/NumpadPanel/GridContainer.get_child(0).grab_focus()

func _on_buy_item(item_name):
	match item_name:
		"Shield":
			if money >= 100:
				money -= 100
				shield_count += 1
				show_result("Shield +1 (Total: %d)" % shield_count)
			else:
				show_result("Not enough money!")
		
		"EasyMode": # ไอเทมลดความยาก
			if money >= 120:
				money -= 120
				# ลดความยากลง 2 หน่วย (แต่ไม่ให้ต่ำกว่าค่าพื้นฐานที่ 0.5)
				difficulty = max(0.5, difficulty - 2.0)
				show_result("Difficulty Reduced!")
				# สุ่มโจทย์ใหม่ทันทีเพื่อให้ความยากที่ซื้อมามีผลเลย
				generate_dynamic_question()
			else:
				show_result("Not enough money!")
				
		"HardMode": # ไอเทมเพิ่มความยาก (เอาไว้ปั๊มเงิน/EXP)
			if money >= 50: # ราคาถูกหน่อยเพราะทำให้เล่นยากขึ้น
				money -= 50
				difficulty += 3.0
				show_result("Difficulty Increased! (More Reward)")
				generate_dynamic_question()
			else:
				show_result("Not enough money!")

	update_game_ui()

func setup_shop_ui():
	var btn_shield = shop_buttons.get_node("Shield")
	var btn_easy = shop_buttons.get_node("EasyMode")
	var btn_hard = shop_buttons.get_node("HardMode")
	
	# ตั้งค่าข้อความบนปุ่ม
	btn_shield.text = "Shield (100$)\n shield streak" 
	btn_easy.text = "Easy Mode (120$)\n-2 Difficulty"
	btn_hard.text = "Hard Mode (50$)\n+3 Difficulty"

func _on_shop_timer_timeout():
	setup_shop_ui()
	get_tree().paused = true
	shop_panel.visible = true
	# ให้โฟกัสไปที่ปุ่มแรกของร้านเพื่อให้ใช้ WASD ได้
	shop_buttons.get_child(0).grab_focus()

func _on_skill_selected(skill_id):
	match skill_id:
		1: # Lucky Streak: เพิ่มโอกาสขึ้นครั้งละ 10%
			lucky_chance += 0.10
			print("Lucky Chance increased to: ", int(lucky_chance * 100), "%")
			
		2: # Interest Boost: เพิ่มเงินฐานครั้งละ 5$
			extra_base_reward += 5
			
		3: # Reduce Max EXP: ลด Max EXP ลง 1 (แต่ห้ามต่ำกว่า 2 เพื่อไม่ให้เกมเพี้ยน)
			if level_bar.max_value > 2:
				level_bar.max_value -= 1
				exp_reduction_count += 1
				print("Reduce Max EXP")

	# ปิดเมนูและเล่นเกมต่อ
	$CanvasLayer/LevelUpPanel.visible = false
	get_tree().paused = false
	
	# 2. คืนโฟกัสไปที่ Numpad (จุดสำคัญ)
	# สมมติว่า Numpad ของคุณมี GridContainer และปุ่มอยู่ข้างใน
	focus_numpad()
	update_level_ui()

# --- ระบบlevel ---
func level_up():
	current_level += 1
	# 1. หยุดเกม (ฟิสิกส์และตัวจับเวลาจะหยุด)
	get_tree().paused = true 
	
	# 2. แสดง Panel และ Focus ปุ่มแรกเพื่อให้ใช้ WASD ได้ทันที
	$CanvasLayer/LevelUpPanel.visible = true
	setup_skill_buttons() # สุ่มหรือตั้งค่าปุ่ม
	skill_buttons_container.get_child(0).grab_focus()
	
	
	current_exp = 0 # รีเซ็ตคะแนนใหม่
	level_bar.value = 0
	level_bar.max_value += 1
	update_level_ui()
	update_exp()

func setup_skill_buttons():
	var btn1 = skill_buttons_container.get_child(0)
	var btn2 = skill_buttons_container.get_child(1)
	var btn3 = skill_buttons_container.get_child(2)
	
	btn1.text = "Lucky Streak\n(10% Double EXP)"
	btn2.text = "Interest Boost\n(+5$ Reward)"
	btn3.text = "Lighten Load\n(-1 Max EXP)"
	
	# เชื่อมสัญญาณ (ถ้ายังไม่ได้เชื่อมใน Editor)
	if not btn1.pressed.is_connected(_on_skill_selected):
		btn1.pressed.connect(_on_skill_selected.bind(1))
		btn2.pressed.connect(_on_skill_selected.bind(2))
		btn3.pressed.connect(_on_skill_selected.bind(3))

func update_level_ui():
	if level_label:
		level_label.text = "LV: " + str(current_level)

func update_exp():
	level_bar.value = current_exp
	LevelBarLabel.text = str(current_exp, " / ", level_bar.max_value, " EXP")

# --- ระบบNumpad ---
func _on_numpad_digit(value):
	var current_input = get_current_focused_input()
	if current_input:
		current_input.text += value
		# ตรวจสอบ text_changed ด้วยตนเองเพราะการเปลี่ยน text ผ่านโค้ด signal จะไม่เด้ง
		_on_text_changed(current_input.text, current_input)

# เมื่อได้รับสัญญาณลบ
func _on_numpad_delete():
	var current_input = get_current_focused_input()
	if current_input and current_input.text.length() > 0:
		current_input.text = current_input.text.left(current_input.text.length() - 1)

# ฟังก์ชันหาว่าตอนนี้ผู้เล่นกำลังกรอกช่องไหนอยู่
func get_current_focused_input():
	# ในระบบของคุณ เราจะรู้ได้จาก input_fields
	# แต่เนื่องจาก Numpad แย่ง Focus ไป เราต้องใช้ตัวแปรเก็บไว้
	# หรือหาช่องที่ว่างช่องแรก
	for field in input_fields:
		if field.text == "": 
			return field
	return input_fields.back() # ถ้าเต็มหมดแล้วให้ลงช่องสุดท้าย

# --- ระบบสร้างโจทย์ ---
func generate_dynamic_question():
	for child in container.get_children():
		child.queue_free() 
	
	input_fields.clear()
	correct_answers.clear()

	# --- 1. กำหนดจำนวนตัวเลขตามความยาก ---
	var num_count = 2
	if difficulty > 10: num_count = 3
	if difficulty > 20: num_count = 4
	if difficulty > 30: num_count = 4
	
	var numbers = []
	var operators = []
	var result = 0
	
	# สุ่มตัวเลขตัวแรก
	var first_num = randi_range(1, 10 + int(difficulty))
	numbers.append(first_num)
	result = first_num
	
	# สุ่มตัวเลขและเครื่องหมายตัวถัดๆ ไป
	for i in range(num_count - 1):
		var n = randi_range(1, 10 + int(difficulty))
		var op = ["+", "-"].pick_random() # สุ่มเครื่องหมาย
		
		if op == "+":
			result += n
		else:
			# ป้องกันผลลัพธ์ติดลบ (ถ้าต้องการ)
			if result - n < 0:
				op = "+"
				result += n
			else:
				result -= n
		
		operators.append(op)
		numbers.append(n)
	
	# --- 2. สร้าง Array สมการ (Formula) ---
	# ตัวอย่าง: ["5", "+", "3", "-", "2", "=", "6"]
	var formula = []
	for i in range(numbers.size()):
		formula.append(str(numbers[i]))
		if i < operators.size():
			formula.append(operators[i])
	
	formula.append("=")
	formula.append(str(result))
	
	# --- 3. สุ่มช่องว่าง ---
	var blank_indices = []
	var possible_indices = []
	
	# หาตำแหน่งที่เป็นตัวเลขทั้งหมดใน formula Array
	for i in range(formula.size()):
		if formula[i].is_valid_int():
			possible_indices.append(i)
	
	possible_indices.shuffle()
	
	# จำนวนช่องว่างเพิ่มตามความยาก
	var how_many_blanks = 1
	#if difficulty > 8: how_many_blanks = 2
	#if difficulty > 20: how_many_blanks = 3
	
	# ป้องกันการสุ่มช่องว่างเกินจำนวนตัวเลขที่มี
	how_many_blanks = min(how_many_blanks, possible_indices.size())
	
	for i in range(how_many_blanks):
		blank_indices.append(possible_indices[i])

	# --- 4. วาดโหนดลงจอ ---
	for i in range(formula.size()):
		if i in blank_indices:
			create_input_field(formula[i])
		else:
			create_label(formula[i])
	
	if input_fields.size() > 0:
		input_fields[0].call_deferred("grab_focus")

# --- ระบบตรวจคำตอบ ---
func check_all_answers():
	var all_correct = true
	var first_wrong_field = null # เก็บช่องแรกที่ตอบผิดไว้ดึงโฟกัสกลับ
	
	for i in range(input_fields.size()):
		if input_fields[i].text != correct_answers[i]:
			all_correct = false
			if first_wrong_field == null:
				first_wrong_field = input_fields[i]
			# (ทางเลือก) ล้างข้อความในช่องที่ผิดเพื่อให้พิมพ์ใหม่
			input_fields[i].text = "" 
	
	if all_correct:
		show_result("Correct!")
		if is_boss_mode:
			# เด้งหน้าต่างเลือก Action ทันที
			open_action_menu()
		else :
			difficulty += 1
			
			streak += 1  # เพิ่มสเตก
			# คำนวณเงินที่ได้: (ฐานเงิน 10) * (ความยาก) * (โบนัสสเตก)
			# ยิ่งยากเงินยิ่งเยอะ ยิ่งสเตกเยอะเงินยิ่งคูณหนัก
			var base_reward = 10 + extra_base_reward
			var difficulty_bonus = int(difficulty * 2) 
			var streak_multiplier = 1.0 + (streak * 0.1) # เพิ่มโบนัส 10% ต่อทุก 1 สเตก
			
			var earned_money = int((base_reward + difficulty_bonus) * streak_multiplier)
			money += earned_money
			
					# --- คำนวณ EXP (ใช้โอกาสที่สะสมมา) ---
			var exp_to_add = 1
			# randf() จะสุ่มค่าระหว่าง 0.0 ถึง 1.0
			if randf() <= lucky_chance: 
				exp_to_add = 2
				show_result("LUCKY! 2X EXP")
			
			current_exp += exp_to_add
			
			current_exp += 1
			var tween = create_tween()
			tween.tween_property(level_bar, "value", current_exp, 0.3).set_trans(Tween.TRANS_SINE)
			
			if current_exp >= level_bar.max_value:
				level_up()
			$CharacterBody2D.dash()
			get_node("/root/Main/CharacterBody2D").on_answer_correct()
			update_game_ui()
			update_exp()
			generate_dynamic_question()
	else:
		show_result("Wrong!")
		if is_boss_mode:pass
		else :
			if shield_count > 0:
				shield_count -= 1 # หักโล่ออก 1 อัน
				show_result("Shield Used! (%d Left)" % shield_count)
			else:
				streak = 0 # รีเซ็ตสเตกเป็นศูนย์ทันที!
				difficulty = max(1.0, difficulty - 1.0) 
			
			get_node("/root/Main/CharacterBody2D").on_answer_wrong()
			update_game_ui()
			update_exp()
			# ไม่ต้องเรียก generate_dynamic_question() เพื่อให้โจทย์เดิมยังอยู่
			# ดึงโฟกัสกลับไปช่องที่ผิดเพื่อให้พิมพ์ใหม่ได้เลย
		if first_wrong_field:
			first_wrong_field.grab_focus()

# ฟังก์ชันอัปเดตตัวเลขบนหน้าจอ
func update_game_ui():
	if streak_label:
		streak_label.text = "x" + str(streak)
	if money_label:
		money_label.text = str(money) + "$"

# --- ฟังก์ชันเสริม (Helper Functions) ---
func update_time_display():
	# คำนวณนาทีและวินาที
	var minutes = int(elapsed_time) / 60
	var seconds = int(elapsed_time) % 60
	
	# แสดงผลในรูปแบบ 00:00
	# %02d คือการบังคับให้เป็นเลข 2 หลัก เช่น 01, 02
	total_time_label.text = "Time Survived: %02d:%02d" % [minutes, seconds]

func stop_game():
	is_game_over = true

func show_result(result):
	$CanvasLayer/show.visible = true
	$CanvasLayer/show/Label.text = result
	await get_tree().create_timer(0.5).timeout
	$CanvasLayer/show.visible = false

func create_label(text):
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 45)
	# ตั้งค่าให้ขยายตัวและอยู่กึ่งกลาง
	#label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(label)

func create_input_field(answer):
	var line_edit = LineEdit.new()
	line_edit.custom_minimum_size.x = 100
	line_edit.max_length = 4
	line_edit.add_theme_font_size_override("font_size", 45)
	line_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	# --- จุดสำคัญ: ปิด Focus ของ LineEdit ---
	line_edit.focus_mode = Control.FOCUS_NONE # ผู้เล่นจะกด WASD ไปที่นี่ไม่ได้
	line_edit.editable = false # ป้องกันการพิมพ์จากคีย์บอร์ดโดยตรง (ถ้าต้องการ)
	
	correct_answers.append(answer)
	input_fields.append(line_edit)
	container.add_child(line_edit)

func _on_text_changed(new_text, current_edit):
	if new_text != "" and not new_text.is_valid_int() and new_text != "-":
		current_edit.text = ""

func _on_input_gui(event, current_edit):
	if event is InputEventKey and event.pressed:
		var current_idx = input_fields.find(current_edit)
		
		if event.is_action_pressed("shift_key"):
			if $CanvasLayer/LevelUpPanel.visible:
				var current_btn = get_viewport().gui_get_focus_owner()
				if current_btn and $CanvasLayer/LevelUpPanel/VBoxContainer/SkillButtonsContainer.is_ancestor_of(current_btn):
					current_btn.emit_signal("pressed")
					get_viewport().set_input_as_handled()
		
		# ใช้คีย์หลัก (Enter) หรือคีย์รอง (Numpad Enter)
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			# บอกให้ Godot รู้ว่าเราจัดการ Event นี้แล้ว กันมันส่งไปที่อื่น
			get_viewport().set_input_as_handled() 
			
			if current_idx < input_fields.size() - 1:
				input_fields[current_idx + 1].grab_focus()
			else:
				check_all_answers()
				
		if event.keycode == KEY_BACKSPACE and current_edit.text == "":
			if current_idx > 0:
				input_fields[current_idx - 1].grab_focus()
				input_fields[current_idx - 1].text = ""
