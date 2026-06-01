extends Node

class_name AbilitySystem

signal ability_unlocked(ability_name: String)
signal synergy_activated(synergy_name: String)

var player: Node2D
var active_abilities: Dictionary = {}
var active_synergies: Array[String] = []

func _ready() -> void:
	player = get_tree().root.get_node_or_null("Game/Player")
	if not player:
		print("ОШИБКА: Игрок не найден для AbilitySystem")
		return
	print("AbilitySystem инициализирован")

func register_ability(ability_name: String, ability_data: Dictionary) -> void:
	active_abilities[ability_name] = ability_data
	ability_unlocked.emit(ability_name)

func activate_ability(ability_name: String) -> void:
	if ability_name not in active_abilities:
		print("Способность '%s' не существует" % ability_name)
		return
	var ability = active_abilities[ability_name]
	execute_ability(ability_name, ability)

func execute_ability(ability_name: String, ability_data: Dictionary) -> void:
	print("Способность активирована: %s" % ability_name)
