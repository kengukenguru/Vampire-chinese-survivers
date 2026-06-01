extends Node2D

# ============================================================================
# GAME MANAGER - Главный контроллер игры
# ============================================================================
# Этот скрипт управляет всеми основными системами игры:
# - Спавн врагов
# - Система волн
# - Управление игроком
# - Счёт и статистика
# - Состояние игры (играет, пауза, конец)
# ============================================================================

# Сигналы (события, которые могут слушать другие объекты)
signal wave_changed(wave_number: int)
signal score_changed(new_score: int)
signal game_over

# Импортируем классы врагов и менеджеры
# Они будут созданы в отдельных файлах
var player: Node2D
var enemy_spawner: Node2D
var ui_manager: CanvasLayer
var ability_system: Node
var passive_system: Node

# Основные параметры игры
var current_wave: int = 1
var current_score: int = 0
var game_time: float = 0.0
var is_paused: bool = false
var is_game_over: bool = false

# Параметры волн
var wave_duration: float = 60.0  # Длительность волны в секундах
var wave_enemy_count: int = 10   # Начальное количество врагов
var wave_difficulty: float = 1.0 # Множитель сложности (увеличивается с волнами)

# Контейнеры для врагов и эффектов
var enemies: Node2D
var effects: Node2D

# ============================================================================
# _ready() - Инициализация при запуске сцены
# ============================================================================
func _ready() -> void:
	# Получаем ссылки на главные компоненты
	player = get_node_or_null("Player")
	enemies = get_node_or_null("Enemies")
	effects = get_node_or_null("Effects")
	ui_manager = get_node_or_null("UILayer")
	
	# Если компоненты не найдены, создаём их
	if not player:
		print("ОШИБКА: Player не найден в сцене!")
		return
	
	if not enemies:
		enemies = Node2D.new()
		enemies.name = "Enemies"
		add_child(enemies)
	
	if not effects:
		effects = Node2D.new()
		effects.name = "Effects"
		add_child(effects)
	
	# Инициализируем системы
	setup_ability_system()
	setup_passive_system()
	setup_ui()
	
	# Начинаем игру
	start_wave()

# ============================================================================
# _process(delta) - Вызывается каждый кадр
# delta - время, прошедшее с последнего кадра (для плавного движения)
# ============================================================================
func _process(delta: float) -> void:
	# Если игра не на паузе, продолжаем
	if not is_paused and not is_game_over:
		game_time += delta
		
		# Проверяем, закончилась ли волна
		if game_time >= wave_duration:
			next_wave()
		
		# Проверяем, жив ли игрок
		if player and player.health <= 0:
			end_game()

# ============================================================================
# _input(event) - Обработка входа (клавиши, касания)
# ============================================================================
func _input(event: InputEvent) -> void:
	# ESC для паузы
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()
	
	# Мобильный ввод (касания)
	if event is InputEventScreenTouch:
		handle_mobile_input(event)

# ============================================================================
# Система волн
# ============================================================================

# Начинает новую волну
func start_wave() -> void:
	current_wave += 1
	game_time = 0.0
	
	# Увеличиваем сложность с каждой волной
	wave_difficulty = 1.0 + (current_wave - 1) * 0.15
	
	# Рассчитываем количество врагов в волне
	var enemies_in_wave = int(wave_enemy_count * wave_difficulty)
	
	print("Волна %d начата! Враги: %d, Сложность: %.2f" % [current_wave, enemies_in_wave, wave_difficulty])
	
	# Отправляем сигнал об изменении волны
	wave_changed.emit(current_wave)
	
	# Спавним врагов (если есть spawner)
	if enemy_spawner:
		enemy_spawner.spawn_wave(enemies_in_wave)

# Переход на следующую волну
func next_wave() -> void:
	start_wave()

# ============================================================================
# Система счёта
# ============================================================================

# Добавляем очки
func add_score(points: int) -> void:
	current_score += points
	score_changed.emit(current_score)

# ============================================================================
# Система способностей
# ============================================================================

# Инициализирует систему способностей
func setup_ability_system() -> void:
	ability_system = Node.new()
	ability_system.name = "AbilitySystem"
	add_child(ability_system)
	
	# Инициализируем стандартные способности
	# (полный список будет в отдельном файле)

# ============================================================================
# Система пассивов
# ============================================================================

# Инициализирует систему пассивных бонусов
func setup_passive_system() -> void:
	passive_system = Node.new()
	passive_system.name = "PassiveSystem"
	add_child(passive_system)

# ============================================================================
# Система UI
# ============================================================================

# Инициализирует UI (интерфейс)
func setup_ui() -> void:
	if not ui_manager:
		ui_manager = CanvasLayer.new()
		ui_manager.name = "UILayer"
		add_child(ui_manager)
	
	# Здесь будут созданы элементы UI

# ============================================================================
# Пауза игры
# ============================================================================

func toggle_pause() -> void:
	is_paused = !is_paused
	get_tree().paused = is_paused
	print("Игра %s" % ["на паузе" if is_paused else "продолжена"])

# ============================================================================
# Конец игры
# ============================================================================

func end_game() -> void:
	if is_game_over:
		return
	
	is_game_over = true
	print("ИГРА ОКОНЧЕНА! Счёт: %d, Волна: %d, Время: %.1f сек" % [current_score, current_wave, game_time])
	
	# Останавливаем врагов
	get_tree().paused = true
	
	# Отправляем сигнал конца игры
	game_over.emit()

# ============================================================================
# Мобильный ввод
# ============================================================================

func handle_mobile_input(event: InputEventScreenTouch) -> void:
	# Левая половина экрана - движение
	if event.position.x < get_viewport_rect().size.x / 2:
		if event.pressed:
			# Игрок касается левой стороны экрана - движение
			player.handle_touch_movement(event.position)

# ============================================================================
# Утилиты
# ============================================================================

# Получить случайную позицию врага за пределами экрана
func get_random_enemy_spawn_position() -> Vector2:
	var viewport_size = get_viewport_rect().size
	var margin = 50
	
	# Выбираем случайную сторону
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

# Очистить всех врагов
func clear_enemies() -> void:
	for child in enemies.get_children():
		child.queue_free()
