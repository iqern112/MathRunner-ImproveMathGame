extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		open_shop()

func open_shop():
	get_tree().paused = true
	GameEvents.shop_opened.emit() 

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	await get_tree().create_timer(1).timeout
	queue_free()
