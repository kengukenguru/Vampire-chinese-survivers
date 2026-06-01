extends CharacterBody2D

# ============================================================================
# PLAYER - Скрипт главного персонажа игрока
# ============================================================================
# Управляет:
# - Движением персонажа
# - Здоровьем и защитой
# - Активными способностями
# - Уровнем персонажа и опытом
# - Взаимодействием с врагами и предметами
# ============================================================================

class_name Player

# Сигналы
signal health_changed(new_health: int, max_health: int)
signal level_up(new_level: int)
signal ability_activated(ability_name: String)
signal experience_gained(amount: int)

# ============================================================================
# БАЗА ПЕРСОНАЖА
# ============================================================================

# Текущий тип персонажа
var character_type: String = "monk"  # "monk", "mage", "demon_warrior", "fox_spirit"

# Основные статистики
var health: int = 100
var max_health: int = 100
var experience: int = 0
var level: int = 1
var armor: float = 0.0

# Движение
var speed: float = 200.0
var direction: Vector2 = Vector2.ZERO
var acceleration: float = 800.0
var friction: float = 600.0

# Базовый урон и атаки
var base_damage: float = 10.0
var current_damage: float = 10.0

# Мобильный ввод
var touch_position: Vector2 = Vector2.ZERO
var is_touch_moving: bool = false

# Визуальные компоненты
var sprite: Sprite2D
var collision: CollisionShape2D
var animation_player: AnimationPlayer

# Способности и пассивы
var active_abilities: Array[Dictionary] = []
var passive_bonuses: Array[Dictionary] = []
var active_ability_cooldowns: Dictionary = {}

# ============================================================================
# ИНИЦИАЛИЗАЦИЯ
# ============================================================================

func _ready() -> void:
	# Инициализируем персонажа в зависимости от типа
	setup_character()
	
	# Получаем ссылки на компоненты
	sprite = get_node_or_null("Sprite2D")
	collision = get_node_or_null("CollisionShape2D")
	animation_player = get_node_or_null("AnimationPlayer")
	
	# Устанавливаем начальное здоровье
	health = max_health
	
	print("Персонаж %s инициализирован (HP: %d, Speed: %.1f)" % [character_type, health, speed])

# ============================================================================
# КОНФИГУРАЦИЯ ПЕРСОНАЖЕЙ
# ============================================================================

func setup_character() -> void:
	"""Настраивает персонажа в зависимости от выбранного типа"""
	
	match character_type:
		"monk":
			setup_monk()
		"mage":
			setup_mage()
		"demon_warrior":
			setup_demon_warrior()
		"fox_spirit":
			setup_fox_spirit()
		_:
			print("Неизвестный тип персонажа: %s" % character_type)

# Боевой Монах - быстрый, слабое оружие
func setup_monk() -> void:
	max_health = 80
	health = 80
	speed = 280  # Самый быстрый
	base_damage = 8.0
	
	# Начальные способности
	active_abilities = [
		{
			"name": "quick_strike",
			"damage": 15,
			"cooldown": 1.5,
			"description": "Быстрый удар"
		},
		{
			"name": "spiritual_dodge",
			"damage": 0,
			"cooldown": 3.0,
			"description": "Телепортация для уклонения"
		}
	]
	
	passive_bonuses = [
		{"name": "swift_feet", "value": 0.15, "type": "speed_bonus"}
	]

# Даосский Маг - медленный, мощная магия
func setup_mage() -> void:
	max_health = 120
	health = 120
	speed = 150  # Самый медленный
	base_damage = 12.0
	
	active_abilities = [
		{
			"name": "fireball",
			"damage": 40,
			"cooldown": 2.0,
			"description": "Огненный шар"
		},
		{
			"name": "ice_storm",
			"damage": 35,
			"cooldown": 3.0,
			"description": "Ледяной шторм"
		}
	]
	
	passive_bonuses = [
		{"name": "mana_shield", "value": 0.2, "type": "damage_reduction"}
	]

# Воин-Демон - сбалансированный
func setup_demon_warrior() -> void:
	max_health = 100
	health = 100
	speed = 200  # Средний
	base_damage = 11.0
	
	active_abilities = [
		{
			"name": "demon_slash",
			"damage": 25,
			"cooldown": 1.8,
			"description": "Демонический удар"
		},
		{
			"name": "demon_rage",
			"damage": 30,
			"cooldown": 4.0,
			"description": "Демоническая ярость"
		}
	]
	
	passive_bonuses = [
		{"name": "demon_regeneration", "value": 0.05, "type": "health_regen"}
	]

# Дух Лисы - очень быстрый, ловушки
func setup_fox_spirit() -> void:
	max_health = 90
	health = 90
	speed = 260
	base_damage = 9.0
	
	active_abilities = [
		{
			"name": "fox_fire",
			"damage": 20,
			"cooldown": 1.5,
			"description": "Лисий огонь"
		},
		{
			"name": "spirit_trap",
			"damage": 0,
			"cooldown": 3.5,
			"description": "Ловушка духа (замораживает врагов)"
		}
	]
	
	passive_bonuses = [
		{"name": "fox_evasion", "value": 0.25, "type": "evasion_chance"}
	]

# ============================================================================
# ПРОЦЕСС ИГРЫ
# ============================================================================

func _process(delta: float) -> void:
	# Обновляем направление движения
	update_direction()
	
	# Применяем движение
	apply_movement(delta)
	
	# Обновляем кулдауны способностей
	update_ability_cooldowns(delta)
	
	# Проверяем пассивные регенерации
	apply_passive_regeneration(delta)

# ============================================================================
# ДВИЖЕНИЕ
# ============================================================================

func update_direction() -> void:
	"""Обновляет направление на основе входа"""
	direction = Vector2.ZERO
	
	# Клавиатурный ввод
	if Input.is_action_pressed("ui_right"):
		direction.x += 1
	if Input.is_action_pressed("ui_left"):
		direction.x -= 1
	if Input.is_action_pressed("ui_down"):
		direction.y += 1
	if Input.is_action_pressed("ui_up"):
		direction.y -= 1
	
	# Мобильный ввод
	if is_touch_moving:
		var touch_direction = touch_position - global_position
		if touch_direction.length() > 0:
			direction = touch_direction.normalized()
	
	# Нормализуем направление (чтобы диагональ не была быстрее)
	if direction.length() > 0:
		direction = direction.normalized()

func apply_movement(delta: float) -> void:
	"""Применяет движение к персонажу"""
	var target_velocity = direction * speed
	
	# Плавное ускорение/замедление
	velocity = velocity.lerp(target_velocity, acceleration * delta)
	
	# Применяем физику (сталкиваемся со стенами и врагами)
	move_and_slide()
	
	# Ограничиваем позицию экраном
	clamp_position_to_screen()

func clamp_position_to_screen() -> void:
	"""Не позволяет персонажу выйти за пределы экрана"""
	var viewport_rect = get_viewport_rect()
	var sprite_size = 32  # Приблизительный размер спрайта
	
	global_position.x = clamp(global_position.x, sprite_size, viewport_rect.size.x - sprite_size)
	global_position.y = clamp(global_position.y, sprite_size, viewport_rect.size.y - sprite_size)

# ============================================================================
# МОБИЛЬНЫЙ ВВОД
# ============================================================================

func handle_touch_movement(touch_pos: Vector2) -> void:
	"""Обрабатывает касание для движения"""
	is_touch_moving = true
	touch_position = touch_pos

func stop_touch_movement() -> void:
	"""Прекращает движение при касании"""
	is_touch_moving = false

# ============================================================================
# ЗДОРОВЬЕ И УРОН
# ============================================================================

func take_damage(damage: float) -> void:
	"""Получает урон с учётом брони"""
	# Расчитываем реальный урон с броней
	var reduced_damage = damage * (1.0 - (armor / 100.0))
	health -= int(reduced_damage)
	
	# Визуальный эффект урона
	if sprite:
		sprite.modulate = Color.RED
		await get_tree().create_timer(0.1).timeout
		sprite.modulate = Color.WHITE
	
	print("Персонаж получил урон: %.1f (реальный: %.1f)" % [damage, reduced_damage])
	health_changed.emit(health, max_health)

func heal(amount: int) -> void:
	"""Лечит персонажа"""
	health = min(health + amount, max_health)
	health_changed.emit(health, max_health)

# ============================================================================
# СПОСОБНОСТИ
# ============================================================================

func activate_ability(ability_index: int) -> void:
	"""Активирует способность по индексу"""
	if ability_index >= active_abilities.size():
		return
	
	var ability = active_abilities[ability_index]
	
	# Проверяем кулдаун
	if is_ability_on_cooldown(ability["name"]):
		print("Способность %s еще на кулдауне" % ability["name"])
		return
	
	# Активируем
	match ability["name"]:
		"quick_strike":
			perform_quick_strike()
		"spiritual_dodge":
			perform_spiritual_dodge()
		"fireball":
			perform_fireball()
		"ice_storm":
			perform_ice_storm()
		"demon_slash":
			perform_demon_slash()
		"demon_rage":
			perform_demon_rage()
		"fox_fire":
			perform_fox_fire()
		"spirit_trap":
			perform_spirit_trap()
	
	# Устанавливаем кулдаун
	set_ability_cooldown(ability["name"], ability["cooldown"])
	ability_activated.emit(ability["name"])

func is_ability_on_cooldown(ability_name: String) -> bool:
	return active_ability_cooldowns.get(ability_name, 0.0) > 0.0

func set_ability_cooldown(ability_name: String, cooldown: float) -> void:
	active_ability_cooldowns[ability_name] = cooldown

func update_ability_cooldowns(delta: float) -> void:
	for ability_name in active_ability_cooldowns.keys():
		active_ability_cooldowns[ability_name] -= delta
		if active_ability_cooldowns[ability_name] < 0:
			active_ability_cooldowns[ability_name] = 0

# ============================================================================
# РЕАЛИЗАЦИЯ СПОСОБНОСТЕЙ
# ============================================================================

func perform_quick_strike() -> void:
	"""Боевой монах: быстрый удар"""
	print("Быстрый удар!")
	# Атакуем врагов в радиусе перед нами

func perform_spiritual_dodge() -> void:
	"""Боевой монах: духовный уклон"""
	print("Духовный уклон!")
	# Телепортируемся в случайное место

func perform_fireball() -> void:
	"""Маг: огненный шар"""
	print("Огненный шар!")
	# Создаём огненный шар

func perform_ice_storm() -> void:
	"""Маг: ледяной шторм"""
	print("Ледяной шторм!")

func perform_demon_slash() -> void:
	"""Воин-демон: демонический удар"""
	print("Демонический удар!")

func perform_demon_rage() -> void:
	"""Воин-демон: демоническая ярость"""
	print("Демоническая ярость!")

func perform_fox_fire() -> void:
	"""Дух лисы: лисий огонь"""
	print("Лисий огонь!")

func perform_spirit_trap() -> void:
	"""Дух лисы: ловушка духа"""
	print("Ловушка духа!")

# ============================================================================
# ОПЫТ И УРОВНИ
# ============================================================================

func gain_experience(amount: int) -> void:
	"""Получает опыт и проверяет повышение уровня"""
	experience += amount
	experience_gained.emit(amount)
	
	# Требуемый опыт для следующего уровня
	var xp_for_next_level = 100 * level
	
	if experience >= xp_for_next_level:
		level_up()

func level_up() -> void:
	"""Повышает уровень персонажа"""
	level += 1
	experience = 0
	
	# Увеличиваем характеристики
	max_health += 20
	health = max_health
	base_damage += 2.0
	
	print("Уровень повышен до %d!" % level)
	level_up.emit(level)

# ============================================================================
# ПАССИВНЫЕ БОНУСЫ
# ============================================================================

func apply_passive_regeneration(delta: float) -> void:
	"""Применяет пассивную регенерацию"""
	for passive in passive_bonuses:
		if passive["type"] == "health_regen":
			var regen_amount = max_health * passive["value"] * delta
			health = min(health + int(regen_amount), max_health)

func get_total_damage() -> float:
	"""Возвращает общий урон с учётом всех бонусов"""
	var total = base_damage
	
	for passive in passive_bonuses:
		if passive["type"] == "damage_bonus":
			total *= (1.0 + passive["value"])
	
	return total

# ============================================================================
# УТИЛИТЫ
# ============================================================================

func get_character_info() -> Dictionary:
	"""Возвращает всю информацию о персонаже"""
	return {
		"type": character_type,
		"level": level,
		"health": health,
		"max_health": max_health,
		"experience": experience,
		"damage": get_total_damage(),
		"speed": speed,
		"armor": armor
	}
