extends Node

# ============================================================================
# ABILITY SYSTEM - Система активных способностей
# ============================================================================
# Управляет активными способностями, синергиями между ними
# и эффектами вращения способностей во время боя
# ============================================================================

class_name AbilitySystem

# Сигналы
signal ability_unlocked(ability_name: String)
signal synergy_activated(synergy_name: String)

# Ссылки
var player: Node2D
var game_manager: Node2D

# Активные способности
var active_abilities: Dictionary = {}

# Синергии (комбинации способностей для увеличенного эффекта)
var synergies: Dictionary = {
	# Маг + Магия
	"mage_fire_ice": {
		"abilities": ["fireball", "ice_storm"],
		"bonus": 1.5,  # 50% увеличение урона
		"description": "Огонь и лёд объединяются"
	},
	# Монах + Скорость
	"monk_speed": {
		"abilities": ["quick_strike", "spiritual_dodge"],
		"bonus": 1.8,
		"description": "Ультра-скорость"
	},
	# Воин-демон + Ярость
	"demon_rage": {
		"abilities": ["demon_slash", "demon_rage"],
		"bonus": 2.0,
		"description": "Демоническая ярость активирована"
	},
	# Лиса + Ловушка
	"fox_trap": {
		"abilities": ["fox_fire", "spirit_trap"],
		"bonus": 1.7,
		"description": "Лисьи ловушки активированы"
	}
}

# Активные синергии
var active_synergies: Array[String] = []

# ============================================================================
# _ready() - Инициализация
# ============================================================================
func _ready() -> void:
	# Ищем игрока
	player = get_tree().root.get_node_or_null("Game/Player")
	if not player:
		print("ОШИБКА: Игрок не найден для AbilitySystem")
		return
	
	print("AbilitySystem инициализирован")

# ============================================================================
# Регистрация способностей
# ============================================================================

func register_ability(ability_name: String, ability_data: Dictionary) -> void:
	"""Регистрирует новую способность в системе"""
	active_abilities[ability_name] = ability_data
	ability_unlocked.emit(ability_name)
	print("Способность '%s' зарегистрирована" % ability_name)

# ============================================================================
# Активация способностей
# ============================================================================

func activate_ability(ability_name: String) -> void:
	"""Активирует способность"""
	if ability_name not in active_abilities:
		print("Способность '%s' не существует" % ability_name)
		return
	
	var ability = active_abilities[ability_name]
	
	# Проверяем синергии
	check_synergies(ability_name)
	
	# Выполняем способность
	execute_ability(ability_name, ability)

func execute_ability(ability_name: String, ability_data: Dictionary) -> void:
	"""Выполняет логику способности"""
	match ability_name:
		# ===== Боевой Монах =====
		"quick_strike":
			execute_quick_strike(ability_data)
		"spiritual_dodge":
			execute_spiritual_dodge(ability_data)
		
		# ===== Даосский Маг =====
		"fireball":
			execute_fireball(ability_data)
		"ice_storm":
			execute_ice_storm(ability_data)
		
		# ===== Воин-Демон =====
		"demon_slash":
			execute_demon_slash(ability_data)
		"demon_rage":
			execute_demon_rage(ability_data)
		
		# ===== Дух Лисы =====
		"fox_fire":
			execute_fox_fire(ability_data)
		"spirit_trap":
			execute_spirit_trap(ability_data)

# ============================================================================
# Монах - Способности
# ============================================================================

func execute_quick_strike(ability_data: Dictionary) -> void:
	"""Быстрый удар - атакует врагов в радиусе перед монахом"""
	var damage = ability_data.get("damage", 15)
	var range_radius = 100
	
	# Ищем врагов рядом
	var enemies = get_nearby_enemies(range_radius)
	
	for enemy in enemies:
		if enemy.has_method("take_damage"):
			var actual_damage = get_synergy_damage(damage, "quick_strike")
			enemy.take_damage(actual_damage)
	
	print("Быстрый удар! Поражено врагов: %d" % enemies.size())

func execute_spiritual_dodge(ability_data: Dictionary) -> void:
	"""Телепортация - монах прыгает в случайное место"""
	if not player:
		return
	
	# Генерируем случайное смещение
	var dodge_distance = 150
	var random_angle = randf() * TAU
	var new_position = player.global_position + Vector2(cos(random_angle), sin(random_angle)) * dodge_distance
	
	# Ограничиваем позицию
	new_position.x = clamp(new_position.x, 32, get_viewport_rect().size.x - 32)
	new_position.y = clamp(new_position.y, 32, get_viewport_rect().size.y - 32)
	
	player.global_position = new_position
	print("Духовный уклон! Позиция: %.0f, %.0f" % [new_position.x, new_position.y])

# ============================================================================
# Маг - Способности
# ============================================================================

func execute_fireball(ability_data: Dictionary) -> void:
	"""Огненный шар - наносит урон врагам в радиусе"""
	var damage = ability_data.get("damage", 40)
	var explosion_radius = 200
	
	# Берём позицию игрока
	var explosion_center = player.global_position if player else Vector2.ZERO
	
	# Ищем врагов в радиусе взрыва
	var enemies = get_enemies_in_radius(explosion_center, explosion_radius)
	
	for enemy in enemies:
		if enemy.has_method("take_damage"):
			var actual_damage = get_synergy_damage(damage, "fireball")
			enemy.take_damage(actual_damage)
	
	print("Огненный шар! Урон: %.0f, Поражено: %d" % [damage, enemies.size()])

func execute_ice_storm(ability_data: Dictionary) -> void:
	"""Ледяной шторм - замораживает и наносит урон"""
	var damage = ability_data.get("damage", 35)
	var freeze_radius = 250
	
	var freeze_center = player.global_position if player else Vector2.ZERO
	var enemies = get_enemies_in_radius(freeze_center, freeze_radius)
	
	for enemy in enemies:
		if enemy.has_method("take_damage"):
			var actual_damage = get_synergy_damage(damage, "ice_storm")
			enemy.take_damage(actual_damage)
			
			# Замораживаем врага (снижаем скорость)
			if enemy.has_property("speed"):
				enemy.speed *= 0.3
				await get_tree().create_timer(3.0).timeout
				enemy.speed /= 0.3
	
	print("Ледяной шторм! Врагов заморожено: %d" % enemies.size())

# ============================================================================
# Воин-Демон - Способности
# ============================================================================

func execute_demon_slash(ability_data: Dictionary) -> void:
	"""Демонический удар - мощный удар в направлении врага"""
	var damage = ability_data.get("damage", 25)
	
	# Ищем ближайшего врага
	var nearest_enemy = get_nearest_enemy()
	
	if nearest_enemy and nearest_enemy.has_method("take_damage"):
		var actual_damage = get_synergy_damage(damage, "demon_slash")
		nearest_enemy.take_damage(actual_damage)
		print("Демонический удар! Урон: %.0f" % actual_damage)

func execute_demon_rage(ability_data: Dictionary) -> void:
	"""Демоническая ярость - атакует всех врагов вокруг"""
	var damage = ability_data.get("damage", 30)
	var rage_radius = 300
	
	var rage_center = player.global_position if player else Vector2.ZERO
	var enemies = get_enemies_in_radius(rage_center, rage_radius)
	
	for enemy in enemies:
		if enemy.has_method("take_damage"):
			var actual_damage = get_synergy_damage(damage, "demon_rage")
			enemy.take_damage(actual_damage)
	
	print("Демоническая ярость! Урон: %.0f, Врагов атаковано: %d" % [damage, enemies.size()])

# ============================================================================
# Дух Лисы - Способности
# ============================================================================

func execute_fox_fire(ability_data: Dictionary) -> void:
	"""Лисий огонь - выпускает несколько снарядов"""
	var damage = ability_data.get("damage", 20)
	var projectile_count = 5
	
	for i in range(projectile_count):
		var angle = (TAU / projectile_count) * i
		# Здесь можно создать визуальные снаряды
		print("Лисий огонь #%d в направлении %.1f градусов" % [i + 1, angle])
	
	print("Лисий огонь! Выпущено снарядов: %d" % projectile_count)

func execute_spirit_trap(ability_data: Dictionary) -> void:
	"""Ловушка духа - замораживает врагов на месте"""
	var trap_radius = 200
	
	var trap_center = player.global_position if player else Vector2.ZERO
	var enemies = get_enemies_in_radius(trap_center, trap_radius)
	
	for enemy in enemies:
		if enemy.has_method("take_damage"):
			# Замораживаем врага
			if enemy.has_property("speed"):
				var original_speed = enemy.speed
				enemy.speed = 0
				
				# Даём визуальный эффект
				await get_tree().create_timer(2.0).timeout
				enemy.speed = original_speed
	
	print("Ловушка духа! Врагов заморожено: %d на 2 сек" % enemies.size())

# ============================================================================
# Синергии (Бонусы при комбинации способностей)
# ============================================================================

func check_synergies(activated_ability: String) -> void:
	"""Проверяет активированы ли синергии"""
	for synergy_name in synergies.keys():
		var synergy_data = synergies[synergy_name]
		var abilities_in_synergy = synergy_data.get("abilities", [])
		
		# Проверяем, есть ли все способности синергии у игрока
		if activated_ability in abilities_in_synergy:
			# Проверяем наличие всех способностей для синергии
			var all_abilities_present = true
			for ability_name in abilities_in_synergy:
				if ability_name not in active_abilities:
					all_abilities_present = false
					break
			
			if all_abilities_present and synergy_name not in active_synergies:
				activate_synergy(synergy_name)

func activate_synergy(synergy_name: String) -> void:
	"""Активирует синергию"""
	if synergy_name in active_synergies:
		return
	
	active_synergies.append(synergy_name)
	var synergy = synergies[synergy_name]
	
	print("🔥 СИНЕРГИЯ АКТИВИРОВАНА: %s" % synergy.get("description", synergy_name))
	synergy_activated.emit(synergy_name)

func get_synergy_damage(base_damage: float, ability_name: String) -> float:
	"""Возвращает урон с учётом активных синергий"""
	var final_damage = base_damage
	
	for synergy_name in active_synergies:
		var synergy = synergies[synergy_name]
		if ability_name in synergy.get("abilities", []):
			final_damage *= synergy.get("bonus", 1.0)
	
	return final_damage

# ============================================================================
# Утилиты
# ============================================================================

func get_nearby_enemies(radius: float) -> Array:
	"""Возвращает всех врагов в радиусе"""
	return get_enemies_in_radius(player.global_position if player else Vector2.ZERO, radius)

func get_enemies_in_radius(center: Vector2, radius: float) -> Array:
	"""Возвращает врагов в указанном радиусе"""
	var enemies_container = get_tree().root.get_node_or_null("Game/Enemies")
	if not enemies_container:
		return []
	
	var nearby_enemies = []
	for enemy in enemies_container.get_children():
		var distance = center.distance_to(enemy.global_position)
		if distance <= radius:
			nearby_enemies.append(enemy)
	
	return nearby_enemies

func get_nearest_enemy() -> Node2D:
	"""Возвращает ближайшего врага"""
	var enemies_container = get_tree().root.get_node_or_null("Game/Enemies")
	if not enemies_container or enemies_container.get_child_count() == 0:
		return null
	
	var nearest = null
	var nearest_distance = INF
	
	for enemy in enemies_container.get_children():
		var distance = player.global_position.distance_to(enemy.global_position) if player else INF
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = enemy
	
	return nearest
