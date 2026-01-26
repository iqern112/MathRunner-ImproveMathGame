extends Control

@onready var level_bar = $ProgressBar
@onready var level_label = $ProgressBar/Label

var lucky_exp: int = 0
var reduce_exp_cap: int = 0
var base_max_exp = 3.0
var current_exp = 0
var current_level = 1

func _ready() -> void:
	GameEvents.correct_answer_signal.connect(on_answer_correct)
	#GameEvents.skill_lucky.connect(lucky_effects)
	#GameEvents.skill_learn.connect(reduce_exp)
	GameEvents.add_skill.connect(update_exp_cap)

func update_exp_cap(_skill = null, _amt = null):
	# 1. คำนวณค่า Max ใหม่
	var current_max = EffectProcessor.calculate_max_exp(base_max_exp)
	
	# 2. ใช้ Tween ค่อยๆ หดหลอด EXP (จะดูสวยกว่าหดวับทันที)
	var tween = create_tween()
	tween.tween_property(level_bar, "max_value", current_max, 0.2).set_trans(Tween.TRANS_SINE)
	
	# 3. เช็คเงื่อนไขหลัง Tween จบ (หรือเช็คทันทีก็ได้)
	# ถ้า current_exp ดันมากกว่าหรือเท่ากับค่า Max ใหม่
	if current_exp >= current_max:
		var overflow = current_exp - int(current_max)
		# เรียกเลเวลอัปพร้อมทบค่าที่เหลือ
		level_up(overflow)

func on_answer_correct():
	if GameEvents.is_stop: return
	
	var bonus_exp = EffectProcessor.get_chance_bonus(BaseEffect.StatType.EXP_BONUS)
	current_exp += 1 + int(bonus_exp)
	
	# --- 1. วิ่งหลอด EXP ปกติ ---
	var tween = create_tween()
	tween.tween_property(level_bar, "value", current_exp, 0.3).set_trans(Tween.TRANS_SINE)
	
	# --- 2. รอให้ Tween วิ่งเสร็จก่อนค่อยเช็คเลเวลอัป (ถ้าอยากให้ดูสมจริง) ---
	# หรือจะเช็คทันทีก็ได้ถ้าต้องการความรวดเร็ว
	if current_exp >= level_bar.max_value:
		# รอให้หลอดวิ่งจนเต็มประจุ (0.3 วินาทีตาม Tween)
		await tween.finished 
		var overflow = current_exp - int(level_bar.max_value)
		level_up(overflow)

func level_up(overflow: int = 0):
	current_level += 1
	current_exp = overflow
	base_max_exp += 1 
	
	# อัปเดต Max Value ใหม่
	update_exp_cap()
	
	# --- 3. จังหวะการไหลลื่นของหลอดตอนเลเวลอัป ---
	# รีเซ็ตหลอดเป็น 0 ทันที (หรือจะทำ Tween วิ่งลงเร็วๆ ก็ได้)
	level_bar.value = 0 
	
	# วิ่งหลอดจาก 0 ไปยังค่าที่ทบมา (Overflow)
	var tween = create_tween()
	tween.tween_property(level_bar, "value", current_exp, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	update_level_ui()
	GameEvents.level_up_signal.emit()
	
	# เช็คเผื่อกรณีเลเวลอัปซ้อน
	if current_exp >= level_bar.max_value:
		await tween.finished
		var extra_overflow = current_exp - int(level_bar.max_value)
		level_up(extra_overflow)


func update_level_ui():
	if level_label:
		level_label.text = "Level: " + str(current_level)
		# ทำ Tween ให้ตัวหนังสือเด้ง (Punch Effect)
		var t = create_tween()
		level_label.pivot_offset = level_label.size / 2 # ตั้งจุดหมุนไว้กลางตัวอักษร
		t.tween_property(level_label, "scale", Vector2(1.5, 1.5), 0.1)
		t.tween_property(level_label, "scale", Vector2(1.0, 1.0), 0.1)
