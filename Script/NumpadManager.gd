# Numpad.gd
extends PanelContainer

signal digit_pressed(value)
signal delete_pressed
signal submit_pressed

@onready var grid = $GridContainer

func _ready():
	var buttons = grid.get_children()
	for btn in buttons:
		btn.focus_mode = Control.FOCUS_ALL
		btn.pressed.connect(_on_btn_clicked.bind(btn.name))
	buttons[0].grab_focus()

func _on_btn_clicked(btn_name):
	match btn_name:
		"Plus": digit_pressed.emit("+")
		"Minus": digit_pressed.emit("-")
		"Multiply": digit_pressed.emit("*")
		"Divide": digit_pressed.emit("/")
		_: digit_pressed.emit(btn_name) # ส่งเลข 0-9

func _input(event):
	if not has_focus_in_group(): return
	
	if event.is_action_pressed("shift_key"):
		submit_pressed.emit()
	if event.is_action_pressed("ui_text_backspace"):
		delete_pressed.emit()


func focus_neighbor(side):
	var current = get_viewport().gui_get_focus_owner()
	if current and is_ancestor_of(current):
		var next = current.find_valid_focus_neighbor(side)
		if next: next.grab_focus()

func has_focus_in_group():
	var current = get_viewport().gui_get_focus_owner()
	return current and is_ancestor_of(current)
