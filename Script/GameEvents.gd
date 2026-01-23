extends Node

var money: int = 0
var is_stop: bool = false
var is_combat: bool = false
signal monster_died

signal correct_answer_signal
signal wrong_answer_signal

signal game_over_triggered

signal level_up_signal

signal on_cut_money(money: int)
signal money_changed(new_amount)

signal skill_learn(value: int)
signal skill_lucky(value: int)
signal on_skill_recive(skill_name : String ,value: int)

signal spawn_monster
signal combat_correct
signal control_to_monster(action: String,value: int)
signal monster_to_control(action: String,value: int)
signal control_to_player(action: String,value: int)
signal combat_panel_open(value: String)
signal item_used

signal route_selected
signal shop_closed
signal open_map
signal first_room_selected
signal fade_out_cut
signal into_out_cut
signal cam_fade_in
signal route_changed(new_type: String)
signal reward
signal open_close_nam

signal campfire_opened
signal shop_opened
signal event_opened
signal treasure_opened
signal elite_opened

signal active_buff

var own_item: Dictionary = {} # เก็บไอเทมที่ซื้อแล้ว
var current_route_type: String
var data_items: Dictionary = {
	"sword": {"title": "Sword", "price": "200", "desc": "Increase damage by 3.", "icon": preload("res://Resouce/ItemTres/sword.tres")},
	"shield": {"title": "Shield", "price": "120", "desc": "Provides 3 defense.", "icon": preload("res://Resouce/ItemTres/shield.tres")},
	"armor": {"title": "Armor", "price": "200", "desc": "Reduce incoming damage by 1 each time.", "icon": preload("res://Resouce/ItemTres/armor.tres")},
	"bow": {"title": "Bow", "price": "120", "desc": "Next action +10 damage.", "icon": preload("res://Resouce/ItemTres/archer.tres")},
	"drill": {"title": "Drill", "price": "150", "desc": "Deal armor-piercing damage 2 time.", "icon": preload("res://Resouce/ItemTres/drill.tres")},
	"potion": {"title": "Heal Potion", "price": "120", "desc": "Restore 5 HP.", "icon": preload("res://Resouce/ItemTres/drug.tres")}
}

func set_route(type: String):
	current_route_type = type
	route_changed.emit(type)

func add_money(amount: int):
	money += amount
	money_changed.emit(money) # ส่งสัญญาณบอก Node อื่นๆ ว่าเงินเปลี่ยนแล้ว

func remove_money(amount: int) -> bool:
	if money >= amount:
		money -= amount
		money_changed.emit(money)
		return true # ลบสำเร็จ
	else:
		return false # เงินไม่พอ ลบไม่สำเร็จ
