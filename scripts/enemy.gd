extends CharacterBody2D

# ============================================================================
# ENEMY - Базовый класс врага
# ============================================================================
# Управляет всеми врагами в игре (различные типы из китайской мифологии)
# Враги преследуют игрока, атакуют его и дают опыт при смерти
# ============================================================================

class_name Enemy

# Сигналы
signal died(enemy: Enemy, position: Vector2)
signal took_damage(damage: float)

# ============================================================================
# ОСНОВНЫЕ ПАРАМЕТРЫ ВРАГА
# ============================================================================

# Тип врага (определяет характеристики)
var enemy_type: String = "juyuanqu"  # "juyuanqu", "yamaluki", "kitsune", "yulin"

# Здоровье
var health: float = 10.0
var max_health: float = 10.0

# Движение
var speed: float = 150.0
var acceleration: float = 500.0
var current_velocity: Vector2 = Vector2.ZERO

# Боевые параметры
var damage: float = 5.0
var attack_range: float = 30.0
var attack_cooldown: float = 1.0
var attack_timer: float = 0.0

# Опыт и награды
var experience_reward: int = 10
var gold_reward: int = 5

# Цель (игрок)
var target: Node2D
var target_distance: float = 0.0

# Визуальные компоненты
var sprite: Sprite2D
var collision: CollisionShape2D
var animation_player: AnimationPlayer

# Параметры врага в игре
var is_alive: bool = true
var game_manager: Node2D

# ============================================================================
# _ready() - Инициализация при создании
# ============================================================================
func _ready() -> void:
	# Настраиваем врага в зависимости от типа
	setup_enemy_type()
	
	# Получаем ссылки на компоненты
	sprite = get_node_or_null("Sprite2D")
	collision = get_node_or_null("CollisionShape2D")
	animation_player = get_node_or_null("AnimationPlayer")
	
	# Ищем игрока
	target = get_tree().root.get_node_or_null("Game/Player")
	if not target:
		print("ОШИБКА: Игрок не найден для врага %s" % enemy_type)
		queue_free()
		return
	
	# Ищем менеджер игры
	game_manager = get_tree().root.get_node_or_null("Game")
	
	# Устанавливаем начальное здоровье
	health = max_health
	
	print("Враг %s создан (HP: %.0f, Damage: %.0f)" % [enemy_type, health, damage])

# ============================================================================
# _process(delta) - Обновление каждый кадр
# ============================================================================
func _process(delta: float) -> void:
	if not is_alive or not target:
		return
	
	# Вычисляем направление к игроку
	var direction_to_target = (target.global_position - global_position).normalized()
	target_distance = global_position.distance_to(target.global_position)
	
	# Двигаемся к цели
	move_towards_target(direction_to_target, delta)
	
	# Применяем движение
	current_velocity = velocity.lerp(direction_to_target * speed, acceleration * delta)
	velocity = current_velocity
	move_and_slide()
	
	# Обновляем кулдаун атаки
	if attack_timer > 0:
		attack_timer -= delta
	
	# Атакуем, если близко
	if target_distance <= attack_range and attack_timer <= 0:
		attack_player()

# ============================================================================
# Типы врагов (из китайской мифологии)
# ============================================================================

# Цзюаньцюй - быстрые слабые духи
func setup_juyuanqu() -> void:
	max_health = 10.0
	health = 10.0
	speed = 180.0
	damage = 5.0
	attack_range = 25.0
	experience_reward = 10
	gold_reward = 3

# Ямалуки - средние сильные демоны
func setup_yamaluki() -> void:
	max_health = 25.0
	health = 25.0
	speed = 120.0
	damage = 12.0
	attack_range = 35.0
	attack_cooldown = 1.5
	experience_reward = 25
	gold_reward = 8

# Кицунэ - быстрые хитрые духи лис
func setup_kitsune() -> void:
	max_health = 15.0
	health = 15.0
	speed = 200.0
	damage = 8.0
	attack_range = 30.0
	attack_cooldown = 0.8
	experience_reward = 20
	gold_reward = 6

# Юйлин - морские средние враги
func setup_yulin() -> void:
	max_health = 20.0
	health = 20.0
	speed = 140.0
	damage = 7.0
	attack_range = 32.0
	attack_cooldown = 1.2
	experience_reward = 15
	gold_reward = 5

# ============================================================================
# БОССЫ
# ============================================================================

# Нэчжа - небесный генерал (сильный босс)
func setup_nezha_boss() -> void:
	max_health = 200.0
	health = 200.0
	speed = 160.0
	damage = 30.0
	attack_range = 50.0
	attack_cooldown = 0.5
	experience_reward = 500
	gold_reward = 100

# Щитник - король подземелья
func setup_shield_king_boss() -> void:
	max_health = 250.0
	health = 250.0
	speed = 100.0
	damage = 25.0
	attack_range = 40.0
	attack_cooldown = 1.5
	experience_reward = 600
	gold_reward = 120

# Королева Жэньхуан - верховная королева насекомых
func setup_renhuan_queen_boss() -> void:
	max_health = 180.0
	health = 180.0
	speed = 200.0
	damage = 28.0
	attack_range = 45.0
	attack_cooldown = 0.7
	experience_reward = 550
	gold_reward = 110

# Драконий Синь - восточный небесный дракон
func setup_dragon_xin_boss() -> void:
	max_health = 300.0
	health = 300.0
	speed = 180.0
	damage = 40.0
	attack_range = 60.0
	attack_cooldown = 0.6
	experience_reward = 1000
	gold_reward = 200

# ============================================================================
# Выбор типа врага
# ============================================================================
func setup_enemy_type() -> void:
	"""Настраивает врага в зависимости от типа"""
	match enemy_type:
		"juyuanqu":
			setup_juyuanqu()
		"yamaluki":
			setup_yamaluki()
		"kitsune":
			setup_kitsune()
		"yulin":
			setup_yulin()
		"nezha_boss":
			setup_nezha_boss()
		"shield_king_boss":
			setup_shield_king_boss()
		"renhuan_queen_boss":
			setup_renhuan_queen_boss()
		"dragon_xin_boss":
			setup_dragon_xin_boss()
		_:
			print("Неизвестный тип врага: %s" % enemy_type)

# ============================================================================
# Движение
# ============================================================================

func move_towards_target(direction: Vector2, delta: float) -> void:
	"""Двигается в сторону цели (игрока)"""
	# Обновляем позицию
	velocity = velocity.lerp(direction * speed, acceleration * delta)

# ============================================================================
# Боевые действия
# ============================================================================

func attack_player() -> void:
	"""Атакует игрока"""
	if target and target.has_method("take_damage"):
		target.take_damage(damage)
		attack_timer = attack_cooldown
		print("Враг %s атаковал! Урон: %.0f" % [enemy_type, damage])

# ============================================================================
# Получение урона
# ============================================================================

func take_damage(damage_amount: float) -> void:
	"""Получает урон"""
	health -= damage_amount
	took_damage.emit(damage_amount)
	
	# Визуальн��й эффект урона
	if sprite:
		sprite.modulate = Color.RED
		await get_tree().create_timer(0.1).timeout
		sprite.modulate = Color.WHITE
	
	if health <= 0:
		die()

# ============================================================================
# Смерть
# ============================================================================

func die() -> void:
	"""Враг умирает"""
	if not is_alive:
		return
	
	is_alive = false
	
	print("Враг %s умер!" % enemy_type)
	
	# Даём награды
	if game_manager and target and target.has_method("gain_experience"):
		target.gain_experience(experience_reward)
	
	# Отправляем сигнал смерти
	died.emit(self, global_position)
	
	# Создаём визуальный эффект (если есть)
	create_death_effect()
	
	# Удаляем врага со сцены
	queue_free()

# ============================================================================
# Визуальные эффекты
# ============================================================================

func create_death_effect() -> void:
	"""Создаёт эффект смерти врага"""
	# Здесь можно добавить частицы, вспышку света и т.д.
	pass

# ============================================================================
# Утилиты
# ============================================================================

func get_enemy_info() -> Dictionary:
	"""Возвращает информацию о враге"""
	return {
		"type": enemy_type,
		"health": health,
		"max_health": max_health,
		"damage": damage,
		"speed": speed,
		"experience_reward": experience_reward
	}
