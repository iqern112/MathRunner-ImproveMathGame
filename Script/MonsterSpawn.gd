extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		open_monster()

func open_monster():
	GameEvents.is_combat = true
	GameEvents.spawn_monster.emit()
