extends Node

class_name PassiveSystem

signal passive_unlocked(passive_name: String)

var player: Node2D
var active_passives: Dictionary = {}

func _ready() -> void:
	player = get_tree().root.get_node_or_null("Game/Player")
	if not player:
		print("ОШИБКА: Игрок не найден для PassiveSystem")
		return
	print("PassiveSystem инициализирован")

func unlock_passive(passive_name: String, passive_data: Dictionary) -> void:
	active_passives[passive_name] = passive_data
	passive_unlocked.emit(passive_name)
