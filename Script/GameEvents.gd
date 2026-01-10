extends Node

var money: int = 0

signal correct_answer_signal
signal wrong_answer_signal

signal game_over_triggered

signal level_up_signal
signal skill_select(skill_name: String)
signal shop_opened

signal on_cut_money(money: int)
signal money_changed(new_amount)

signal skill_learn(value: int)
signal skill_lucky(value: int)


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
