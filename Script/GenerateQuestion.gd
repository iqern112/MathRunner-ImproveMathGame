extends PanelContainer

@onready var container = $EquationContainer
@onready var numpad = $"../NumpadPanel"

var input_fields = []
var correct_answers = [] 
var difficulty = 1

func _ready() -> void:
	
	numpad.digit_pressed.connect(_on_numpad_digit)
	numpad.delete_pressed.connect(_on_numpad_delete)
	numpad.submit_pressed.connect(check_all_answers)
	
	randomize()
	generate_dynamic_question()

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

func create_input_field(answer):
	var line_edit = LineEdit.new()
	#line_edit.custom_minimum_size.x = 100
	line_edit.max_length = 4
	#line_edit.add_theme_font_size_override("font_size", 45)
	line_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	# --- จุดสำคัญ: ปิด Focus ของ LineEdit ---
	line_edit.focus_mode = Control.FOCUS_NONE # ผู้เล่นจะกด WASD ไปที่นี่ไม่ได้
	line_edit.editable = false # ป้องกันการพิมพ์จากคีย์บอร์ดโดยตรง (ถ้าต้องการ)
	
	correct_answers.append(answer)
	input_fields.append(line_edit)
	container.add_child(line_edit)

func create_label(text):
	var label = Label.new()
	label.text = text
	#label.add_theme_font_size_override("font_size", 45)
	# ตั้งค่าให้ขยายตัวและอยู่กึ่งกลาง
	#label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(label)

func _on_numpad_digit(value):
	var current_input = get_current_focused_input()
	if current_input:
		current_input.text += value
		# ตรวจสอบ text_changed ด้วยตนเองเพราะการเปลี่ยน text ผ่านโค้ด signal จะไม่เด้ง
		_on_text_changed(current_input.text, current_input)

func _on_text_changed(new_text, current_edit):
	if new_text != "" and not new_text.is_valid_int() and new_text != "-":
		current_edit.text = ""

func _on_numpad_delete():
	var current_input = get_current_focused_input()
	if current_input and current_input.text.length() > 0:
		current_input.text = current_input.text.left(current_input.text.length() - 1)

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
		if GameEvents.is_stop:
			GameEvents.combat_correct.emit()
			generate_dynamic_question()
		else :
				GameEvents.correct_answer_signal.emit()
				$"../SkillControl".make_money(difficulty)
				generate_dynamic_question()
	else:
		GameEvents.wrong_answer_signal.emit()
		if first_wrong_field:
			first_wrong_field.grab_focus()

# ฟังก์ชันหาว่าตอนนี้ผู้เล่นกำลังกรอกช่องไหนอยู่
func get_current_focused_input():
	# ในระบบของคุณ เราจะรู้ได้จาก input_fields
	# แต่เนื่องจาก Numpad แย่ง Focus ไป เราต้องใช้ตัวแปรเก็บไว้
	# หรือหาช่องที่ว่างช่องแรก
	for field in input_fields:
		if field.text == "": 
			return field
	return input_fields.back() # ถ้าเต็มหมดแล้วให้ลงช่องสุดท้าย
