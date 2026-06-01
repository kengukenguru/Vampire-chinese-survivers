extends Node

# ============================================================================
# PASSIVE SYSTEM - Система пассивных бонусов
# ============================================================================
# Управляет пассивными способностями, которые дают постоянные бонусы
# Игрок получает новые пассивы при повышении уровня
# ============================================================================

class_name PassiveSystem

# Сигналы
signal passive_unlocked(passive_name: String)
signal passive_synergy_activated(synergy_name: String)

# Ссылки
var player: Node2D
var game_manager: Node2D

# Активные пассивы
var active_passives: Dictionary = {}

# Все доступные пассивы
var all_passives: Dictionary = {
	# ===== Монах =====
	"swift_feet": {
		"name": "Быстрые ноги",
		"description": "Увеличивает скорость на 15%",
		"bonus_type": "speed",
		"value": 0.15,
		"character": "monk"
	},
	"meditation": {
		"name": "Медитация",
		"description": "Восстановление 5% HP за секунду",
		"bonus_type": "health_regen",
		"value": 0.05,
		"character": "monk"
	},
	"evasion": {
		"name": "Уклонение",
		"description": "10% шанс избежать удара",
		"bonus_type": "evasion",
		"value": 0.1,
		"character": "monk"
	},
	
	# ===== Маг =====
	"mana_shield": {
		"name": "Магический щит",
		"description": "Снижает входящий урон на 20%",
		"bonus_type": "damage_reduction",
		"value": 0.2,
		"character": "mage"
	},
	"arcane_amplification": {
		"name": "Аркано-усиление",
		"description": "Увеличивает урон магии на 25%",
		"bonus_type": "spell_damage",
		"value": 0.25,
		"character": "mage"
	},
	"mana_recovery": {
		"name": "Восстановление маны",
		"description": "Восстановление 3% маны за секунду",
		"bonus_type": "mana_regen",
		"value": 0.03,
		"character": "mage"
	},
	
	# ===== Воин-Демон =====
	"demon_regeneration": {
		"name": "Демоническая регенерация",
		"description": "Восстановление 5% HP за каждое убийство",
		"bonus_type": "kill_health_regen",
		"value": 0.05,
		"character": "demon_warrior"
	},
	"demonic_strength": {
		"name": "Демоническая сила",
		"description": "Увеличивает урон на 20%",
		"bonus_type": "damage_bonus",
		"value": 0.2,
		"character": "demon_warrior"
	},
	"demon_armor": {
		"name": "Демонический панцирь",
		"description": "Увеличивает защиту на 10%",
		"bonus_type": "armor",
		"value": 0.1,
		"character": "demon_warrior"
	},
	
	# ===== Дух Лисы =====
	"fox_evasion": {
		"name": "Лисья хитрость",
		"description": "25% шанс избежать удара",
		"bonus_type": "evasion",
		"value": 0.25,
		"character": "fox_spirit"
	},
	"fox_fire_spread": {
		"name": "Распространение лисьего огня",
		"description": "Лисий огонь поражает окружающих врагов",
		"bonus_type": "ability_enhancement",
		"value": 1.0,
		"character": "fox_spirit"
	},
	"spirit_movement": {
		"name": "Духовное движение",
		"description": "Движение на 20% быстрее",
		"bonus_type": "speed",
		"value": 0.2,
		"character": "fox_spirit"
	},
	
	# ===== Универсальные пассивы =====
	"sharp_attack": {
		"name": "Острая атака",
		"description": "Урон увеличен на 10%",
		"bonus_type": "damage_bonus",
		"value": 0.1,
		"character": "universal"
	},
	"blood_thirst": {
		"name": "Кровавая жажда",
		"description": "5% восстановление HP при убийстве",
		"bonus_type": "kill_health_regen",
		"value": 0.05,
		"character": "universal"
	},
	"battle_armor": {
		"name": "Боевая броня",
		"description": "Защита увеличена на 5 единиц",
		"bonus_type": "armor_flat",
		"value": 5.0,
		"character": "universal"
	},
	"experience_boost": {
		"name": "Усиление опыта",
		"description": "Получаемый опыт увеличен на 20%",
		"bonus_type": "experience_multiplier",
		"value": 0.2,
		"character": "universal"
	},
	"lifesteal": {
		"name": "Вампиризм",
		"description": "10% наносимого урона восстанавливает HP",
		"bonus_type": "lifesteal",
		"value": 0.1,
		"character": "universal"
	},
	"critical_strike": {
		"name": "Крит. удар",
		"description": "15% шанс нанести 1.5x урона",
		"bonus_type": "critical_damage",
		"value": 1.5,
		"character": "universal"
	}
}

# Синергии между пассивами
var passive_synergies: Dictionary = {
	"demon_strength_plus": {
		"passives": ["demonic_strength", "demon_armor"],
		"bonus_multiplier": 1.25,
		"description": "Демоническая броня + сила = 25% бонус"
	},
	"magical_mastery": {
		"passives": ["arcane_amplification", "mana_recovery"],
		"bonus_multiplier": 1.3,
		"description": "Полное магическое мастерство = 30% бонус"
	},
	"fox_cunning": {
		"passives": ["fox_evasion", "fox_fire_spread"],
		"bonus_multiplier": 1.4,
		"description": "Лисья хитрость в действии = 40% бонус"
	},
	"aggressive_healing": {
		"passives": ["blood_thirst", "lifesteal"],
		"bonus_multiplier": 1.35,
		"description": "Агрессивное исцеление = 35% бонус"
	}
}

# ============================================================================
# _ready() - Инициализация
# ============================================================================
func _ready() -> void:
	player = get_tree().root.get_node_or_null("Game/Player")
	game_manager = get_tree().root.get_node_or_null("Game")
	
	if not player:
		print("ОШИБКА: Игрок не найден для PassiveSystem")
		return
	
	print("PassiveSystem инициализирован")

# ============================================================================
# Регистрация пассивов
# ============================================================================

func unlock_passive(passive_name: String) -> void:
	"""Разблокирует и активирует пассив"""
	if passive_name in active_passives:
		print("Пассив %s уже активен" % passive_name)
		return
	
	if passive_name not in all_passives:
		print("Пассив %s не существует" % passive_name)
		return
	
	var passive = all_passives[passive_name]
	active_passives[passive_name] = passive
	
	print("🎁 Пассив разблокирован: %s - %s" % [passive["name"], passive["description"]])
	passive_unlocked.emit(passive_name)
	
	# Проверяем синергии
	check_synergies()
	
	# Применяем бонус
	apply_passive_bonus(passive_name, passive)

# ============================================================================
# Применение бонусов
# ============================================================================

func apply_passive_bonus(passive_name: String, passive: Dictionary) -> void:
	"""Применяет бонус пассива к игроку"""
	var bonus_type = passive.get("bonus_type", "")
	var value = passive.get("value", 0.0)
	
	if not player:
		return
	
	match bonus_type:
		"speed":
			player.speed *= (1.0 + value)
		
		"damage_bonus":
			player.base_damage *= (1.0 + value)
		
		"damage_reduction":
			# Это применяется при получении урона
			pass
		
		"health_regen":
			# Уже обрабатывается в _process игрока
			pass
		
		"evasion":
			# Расчитывается при получении урона
			pass
		
		"armor":
			player.armor += value
		
		"armor_flat":
			player.armor += value
		
		"lifesteal":
			# Обрабатывается при нанесении урона
			pass
		
		"critical_damage":
			# Обрабатывается при нанесении урона
			pass
		
		_:
			print("Неизвестный тип бонуса: %s" % bonus_type)

# ============================================================================
# Синергии пассивов
# ============================================================================

func check_synergies() -> void:
	"""Проверяет активированы ли синергии"""
	for synergy_name in passive_synergies.keys():
		var synergy = passive_synergies[synergy_name]
		var required_passives = synergy.get("passives", [])
		
		# Проверяем, есть ли все пассивы для синергии
		var all_passives_present = true
		for passive_name in required_passives:
			if passive_name not in active_passives:
				all_passives_present = false
				break
		
		# Если есть все пассивы, активируем синергию
		if all_passives_present:
			activate_synergy(synergy_name)

func activate_synergy(synergy_name: String) -> void:
	"""Активирует синергию пассивов"""
	var synergy = passive_synergies[synergy_name]
	
	print("⭐ СИНЕРГИЯ ПАССИВОВ: %s" % synergy["description"])
	passive_synergy_activated.emit(synergy_name)
	
	# Применяем бонус синергии (можно добавить визуальный эффект)

# ============================================================================
# Получение случайного пассива
# ============================================================================

func get_random_passive(character_type: String = "universal") -> String:
	"""Возвращает случайный доступный пассив для персонажа"""
	var available_passives = []
	
	for passive_name in all_passives.keys():
		var passive = all_passives[passive_name]
		
		# Проверяем, подходит ли пассив персонажу
		if passive.get("character") == character_type or passive.get("character") == "universal":
			if passive_name not in active_passives:
				available_passives.append(passive_name)
	
	if available_passives.size() == 0:
		return ""
	
	return available_passives[randi() % available_passives.size()]

# ============================================================================
# Утилиты
# ============================================================================

func get_active_passives() -> Array:
	"""Возвращает список активных пассивов"""
	return active_passives.keys()

func get_passive_info(passive_name: String) -> Dictionary:
	"""Возвращает информацию о пассиве"""
	if passive_name in all_passives:
		return all_passives[passive_name]
	return {}

func calculate_damage_reduction() -> float:
	"""Расчитывает общее снижение урона от пассивов"""
	var total_reduction = 0.0
	
	for passive_name in active_passives.keys():
		var passive = active_passives[passive_name]
		if passive.get("bonus_type") == "damage_reduction":
			total_reduction += passive.get("value", 0.0)
	
	return clamp(total_reduction, 0.0, 0.9)  # Максимум 90% защиты

func get_evasion_chance() -> float:
	"""Расчитывает шанс избежать удара"""
	var total_evasion = 0.0
	
	for passive_name in active_passives.keys():
		var passive = active_passives[passive_name]
		if passive.get("bonus_type") == "evasion":
			total_evasion += passive.get("value", 0.0)
	
	return clamp(total_evasion, 0.0, 0.75)  # Максимум 75% уклонения

func get_lifesteal_amount(damage_dealt: float) -> float:
	"""Расчитывает восстановление HP от вампиризма"""
	var total_lifesteal = 0.0
	
	for passive_name in active_passives.keys():
		var passive = active_passives[passive_name]
		if passive.get("bonus_type") == "lifesteal":
			total_lifesteal += passive.get("value", 0.0)
	
	return damage_dealt * total_lifesteal
