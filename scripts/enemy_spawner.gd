extends Node2D

# ============================================================================
# ENEMY SPAWNER - Система спавна врагов
# ============================================================================
# Управляет созданием врагов волнами
# Враги появляются за пределами экрана случайно со всех сторон
# ============================================================================

class_name EnemySpawner

# Ссылки на компоненты
var enemies_container: Node2D
var game_manager: Node2D

# Доступные типы врагов
var enemy_types: Array[String] = ["juyuanqu", "yamaluki", "kitsune", "yulin"]
var boss_types: Array[String] = ["nezha_boss", "shield_king_boss", "renhuan_queen_boss", "dragon_xin_boss"]

# Параметры спавна
var spawn_interval: float = 0.5  # Интервал между спавнами врагов
var spawn_timer: float = 0.0
var enemies_to_spawn: int = 0
var spawned_enemies: int = 0
var is_spawning: bool = false

# Сложность
var difficulty_multiplier: float = 1.0

# Префаб врага (путь до сцены)
var enemy_scene_path: String = "res://scenes/enemy.tscn"

# ============================================================================
# _ready() - Инициализация
# ============================================================================
func _ready() -> void:
	# Ищем контейнер врагов в сцене
	enemies_container = get_parent().get_node_or_null("Enemies")
	if not enemies_container:
		enemies_container = Node2D.new()
		enemies_container.name = "Enemies"
		get_parent().add_child(enemies_container)
	
	# Ищем менеджер игры
	game_manager = get_parent()
	print("EnemySpawner инициализирован")

# ============================================================================
# _process(delta) - Обновление спавна
# ============================================================================
func _process(delta: float) -> void:
	if is_spawning:
		spawn_timer -= delta
		if spawn_timer <= 0 and spawned_enemies < enemies_to_spawn:
			spawn_random_enemy()
			spawn_timer = spawn_interval

# ============================================================================
# Спавн волны врагов
# ============================================================================

func spawn_wave(enemy_count: int) -> void:
	"""Начинает спавн волны с указанным количеством врагов"""
	enemies_to_spawn = enemy_count
	spawned_enemies = 0
	spawn_timer = 0.0
	is_spawning = true
	
	print("Волна начата: будет заспавнено %d врагов" % enemy_count)

# ============================================================================
# Спавн одного врага
# ============================================================================

func spawn_random_enemy() -> void:
	"""Создаёт случайного врага"""
	spawned_enemies += 1
	
	# Выбираем тип врага
	var enemy_type: String
	
	# Каждые 5 врагов может появиться босс
	if randi() % 5 == 0 and spawned_enemies > 10:
		enemy_type = boss_types[randi() % boss_types.size()]
		print("Появился БОСС: %s" % enemy_type)
	else:
		enemy_type = enemy_types[randi() % enemy_types.size()]
	
	# Создаём врага
	create_enemy(enemy_type)

func create_enemy(enemy_type: String) -> void:
	"""Создаёт врага указанного типа"""
	# Создаём новый экземпляр врага
	var enemy = Enemy.new()
	enemy.name = enemy_type
	enemy.enemy_type = enemy_type
	
	# Устанавливаем случайную позицию спавна (за пределами экрана)
	var spawn_pos = get_random_spawn_position()
	enemy.global_position = spawn_pos
	
	# Добавляем врага в контейнер
	enemies_container.add_child(enemy)

# ============================================================================
# Утилиты
# ============================================================================

func get_random_spawn_position() -> Vector2:
	"""Возвращает случайную позицию для спавна враг за пределами экрана"""
	var viewport_size = get_viewport_rect().size
	var margin = 100
	
	# Выбираем случайную сторону экрана
	var side = randi() % 4
	
	match side:
		0:  # Сверху
			return Vector2(randf_range(0, viewport_size.x), -margin)
		1:  # Снизу
			return Vector2(randf_range(0, viewport_size.x), viewport_size.y + margin)
		2:  # Слева
			return Vector2(-margin, randf_range(0, viewport_size.y))
		3:  # Справа
			return Vector2(viewport_size.x + margin, randf_range(0, viewport_size.y))
	
	return Vector2.ZERO

func get_enemy_count() -> int:
	"""Возвращает текущее количество врагов на карте"""
	return enemies_container.get_child_count()

func clear_enemies() -> void:
	"""Удаляет всех врагов со сцены"""
	for child in enemies_container.get_children():
		child.queue_free()
	is_spawning = false
