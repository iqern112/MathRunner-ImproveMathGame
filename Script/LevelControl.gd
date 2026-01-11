extends Control

@onready var level_bar = $ProgressBar
@onready var level_label = $ProgressBar/Label

var lucky_exp: int = 0
var reduce_exp_cap: int = 0

var current_exp = 0
var current_level = 1

func _ready() -> void:
	GameEvents.correct_answer_signal.connect(level_control)
	GameEvents.skill_lucky.connect(lucky_effects)
	GameEvents.skill_learn.connect(reduce_exp)

func level_control():
	if GameEvents.is_combat:
		return
	var ex_plus:int = 0
	if randf() <= 0.4:ex_plus = lucky_exp
	current_exp += 1 + ex_plus
	var tween = create_tween()#bar animad
	tween.tween_property(level_bar, "value", current_exp, 0.3).set_trans(Tween.TRANS_SINE)
	if current_exp >= level_bar.max_value:
		level_up()

func level_up():
	current_level += 1
	current_exp = 0
	level_bar.value = 0
	level_bar.max_value += 1
	var tween = create_tween()#bar animad
	tween.tween_property(level_bar, "value", current_exp, 0.3).set_trans(Tween.TRANS_SINE)
	update_level_ui()
	GameEvents.level_up_signal.emit()
	#update_exp()

func update_level_ui():
	if level_label:
		level_label.text = "level: " + str(current_level)

func lucky_effects(plus_exp: int):
	lucky_exp = plus_exp

func reduce_exp():
	var min_cap = 1
	if level_bar.max_value > reduce_exp_cap:
		level_bar.max_value -= reduce_exp_cap
		if level_bar.max_value < min_cap:
			level_bar.max_value = min_cap
			
		# เช็คทันที: ถ้าค่า Max ใหม่ต่ำกว่า EXP ที่มีอยู่ ให้เลเวลอัพเลย
		if current_exp >= level_bar.max_value:
			level_up()
