extends Control

var next_event_type

func _ready() -> void:
	GameEvents.route_selected.connect(_on_route_chosen)


func _on_route_chosen(type: String):
	next_event_type = type
