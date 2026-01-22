# Numpad.gd
extends PanelContainer

signal digit_pressed(value)
signal delete_pressed
signal submit_pressed

@onready var grid = $GridContainer

func _ready():
	var buttons = grid.get_children()
	var cols = grid.columns # สมมติว่าตั้งค่า GridContainer ไว้ 5 คอลัมน์ตามภาพ
	var total = buttons.size()

	for i in range(total):
		var btn = buttons[i]
		btn.focus_mode = Control.FOCUS_ALL
		btn.pressed.connect(_on_btn_clicked.bind(btn.name))
		
		# --- การตั้งค่าให้กดวน (Focus Wrapping) ---
		
		# 1. วนซ้าย-ขวา
		if i % cols == 0: # ปุ่มอยู่ซ้ายสุด
			btn.focus_neighbor_left = buttons[i + (cols - 1)].get_path()
		if (i + 1) % cols == 0: # ปุ่มอยู่ขวาสุด
			btn.focus_neighbor_right = buttons[i - (cols - 1)].get_path()
			
		# 2. วนบน-ล่าง
		if i < cols: # แถวบนสุด
			# ให้วนไปปุ่มในแถวล่าง (ตำแหน่ง i + คอลัมน์)
			btn.focus_neighbor_top = buttons[i + cols].get_path()
		if i >= cols: # แถวล่างสุด
			# ให้วนไปปุ่มในแถวบน (ตำแหน่ง i - คอลัมน์)
			btn.focus_neighbor_bottom = buttons[i - cols].get_path()


func grab_initial_focus():
	var buttons = grid.get_children()
	if buttons.size() > 0:
		buttons[0].grab_focus()

func _on_btn_clicked(btn_name):
	match btn_name:
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
