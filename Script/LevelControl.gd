extends Control

@onready var level_bar = $ProgressBar
@onready var level_label = $ProgressBar/Label

var current_exp = 0
var current_level = 1

func _ready() -> void:
	GameEvents.correct_answer_signal.connect(level_control)
	

func level_control():
	current_exp += 1
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
