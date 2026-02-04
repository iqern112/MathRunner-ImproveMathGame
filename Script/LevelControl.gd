extends Control

@onready var level_bar = $ProgressBar
@onready var level_label = $ProgressBar/Label
@onready var Update_exp = $ProgressBar/Label2 # ตัวเลขแสดงผล 0/0

var base_max_exp = 5.0 # ปรับ Max ต้นให้สูงขึ้นเล็กน้อย
var current_exp = 0
var current_level = 1

func _ready() -> void:
	GameEvents.correct_answer_signal.connect(on_answer_correct)
	# ตั้งค่าหน้าจอเริ่มต้น
	level_bar.max_value = base_max_exp
	level_bar.value = current_exp
	update_level_ui()

func on_answer_correct():
	if GameEvents.is_stop: return
	
	var bonus_exp = EffectProcessor.get_total_bonus(BaseEffect.StatType.EXP_BONUS)
	current_exp += 1 + int(bonus_exp)
	
	# อัปเดตตัวเลข 0/0 ทันทีที่ได้ EXP
	_update_exp_text()
	
	var tween = create_tween()
	tween.tween_property(level_bar, "value", current_exp, 0.3).set_trans(Tween.TRANS_SINE)
	
	if current_exp >= level_bar.max_value:
		await tween.finished 
		var overflow = current_exp - int(level_bar.max_value)
		level_up(overflow)

func level_up(overflow: int = 0):
	current_level += 1
	current_exp = overflow
	
	# ปรับการเพิ่ม Max EXP ให้ยากขึ้นตามเลเวล (เช่น เพิ่มทีละ 2)
	base_max_exp += 2.0 
	
	# อัปเดตค่า Max ของหลอดเลือดให้ตรงกับ Logic
	level_bar.max_value = base_max_exp
	level_bar.value = 0 
	
	# แสดงผล UI ใหม่
	_update_exp_text()
	update_level_ui()
	
	# วิ่งหลอดจาก 0 ไปยังค่าที่ทบมา (Overflow)
	var tween = create_tween()
	tween.tween_property(level_bar, "value", current_exp, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	GameEvents.level_up_signal.emit()
	
	# เช็คเลเวลอัปซ้อน (Recursive Check)
	if current_exp >= level_bar.max_value:
		await tween.finished
		var extra_overflow = current_exp - int(level_bar.max_value)
		level_up(extra_overflow)

# ฟังก์ชันช่วยอัปเดตตัวเลข EXP (เช่น 2/5)
func _update_exp_text():
	if Update_exp:
		Update_exp.text = str(current_exp) + "/" + str(int(level_bar.max_value))

func update_level_ui():
	if level_label:
		level_label.text = "Lv: " + str(current_level)
		_update_exp_text() # ตรวจสอบให้แน่ใจว่าตัวเลขเปลี่ยนตาม
		
		var t = create_tween()
		level_label.pivot_offset = level_label.size / 2
		t.tween_property(level_label, "scale", Vector2(1.5, 1.5), 0.1)
		t.tween_property(level_label, "scale", Vector2(1.0, 1.0), 0.1)
