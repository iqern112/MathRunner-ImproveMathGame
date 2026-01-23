extends Node2D

const BUFF_DATA = {
	"hp_incress": "+ 8 HP",
	"attack_incress": "+ 3 Attack",
	"block_incress": "+ 3 Block"
}

@onready var buttons = [
	$"../CanvasLayer/Wish/VBoxContainer/Button",
	$"../CanvasLayer/Wish/VBoxContainer/Button2",
	$"../CanvasLayer/Wish/VBoxContainer/Button3"
]
@onready var text_butt = [
	$"../CanvasLayer/Wish/VBoxContainer/Button/Label",
	$"../CanvasLayer/Wish/VBoxContainer/Button2/Label2",
	$"../CanvasLayer/Wish/VBoxContainer/Button3/Label3"
]
@onready var wish_panel =$"../CanvasLayer/Wish"
@onready var plan_panel = $"../CanvasLayer/Plan"
@onready var plan_butt = $"../CanvasLayer/Plan/VBoxContainer/Button"

func _ready() -> void:
	
	_setup_buff_texts()
	for i in range(buttons.size()):
		var btn = buttons[i]
		btn.pressed.connect(_on_buff_selected.bind(i))
	buttons[0].grab_focus()

func _setup_buff_texts() -> void:
	var buff_keys = BUFF_DATA.keys()
	for i in range(text_butt.size()):
		if i < buff_keys.size():
			var key = buff_keys[i]
			text_butt[i].text = BUFF_DATA[key]

func _on_buff_selected(index: int):
	var buff_keys = BUFF_DATA.keys()
	var selected_key = buff_keys[index]
	GameEvents.active_buff.emit(selected_key)
	wish_panel.visible = false
	_open_plan_system()

func _open_plan_system():
	plan_panel.visible = true
	var first_plan_btn = plan_butt
	if first_plan_btn:
		first_plan_btn.grab_focus()

func _on_button_pressed() -> void:
	plan_panel.visible = false
	await get_tree().process_frame
	GameEvents.open_map.emit()
