extends CanvasLayer

# ============================================================================
# UI MANAGER - Управление пользовательским интерфейсом
# ============================================================================
# Отвечает за:
# - Отображение здоровья, опыта, уровня
# - Меню выбора способностей
# - Кнопки управления (особенно для мобильных)
# - Главное меню
# - Экран конца игры
# ============================================================================

class_name UIManager

# Ссылки на компоненты
var game_manager: Node2D
var player: Node2D
var main_menu: Control
var hud_container: Control
var ability_selection_menu: Control
var game_over_menu: Control

# UI элементы
var health_label: Label
var health_bar: ProgressBar
var score_label: Label
var wave_label: Label
var level_label: Label
var xp_bar: ProgressBar

# Кнопки способностей
var ability_buttons: Array[Button] = []

# Кнопки управления
var touch_buttons: Array[TouchButton] = []
var mobile_d_pad: Control

# ============================================================================
# _ready() - Инициализация
# ============================================================================
func _ready() -> void:
	game_manager = get_tree().root.get_node_or_null("Game")
	player = get_tree().root.get_node_or_null("Game/Player")
	
	# Создаём главное меню
	create_main_menu()
	
	print("UIManager инициализирован")

# ============================================================================
# ГЛАВНОЕ МЕНЮ
# ============================================================================

func create_main_menu() -> void:
	"""Создаёт главное меню выбора персонажа"""
	
	main_menu = Control.new()
	main_menu.name = "MainMenu"
	main_menu.anchor_left = 0
	main_menu.anchor_top = 0
	main_menu.anchor_right = 1
	main_menu.anchor_bottom = 1
	add_child(main_menu)
	
	# Заголовок
	var title = Label.new()
	title.text = "🧛 VAMPIRE CHINESE SURVIVORS 🧛"
	title.add_theme_font_size_override("font_size", 48)
	title.anchor_left = 0.5
	title.anchor_top = 0.1
	title.offset_left = -200
	title.offset_top = 0
	main_menu.add_child(title)
	
	# Подзаголовок
	var subtitle = Label.new()
	subtitle.text = "Выберите персонажа"
	subtitle.add_theme_font_size_override("font_size", 24)
	subtitle.anchor_left = 0.5
	subtitle.anchor_top = 0.25
	subtitle.offset_left = -100
	main_menu.add_child(subtitle)
	
	# Кнопки персонажей
	var character_data = [
		{"name": "Боевой Монах", "type": "monk", "color": Color.LIGHT_GRAY},
		{"name": "Даосский Маг", "type": "mage", "color": Color.CYAN},
		{"name": "Воин-Демон", "type": "demon_warrior", "color": Color.RED},
		{"name": "Дух Лисы", "type": "fox_spirit", "color": Color.ORANGE}
	]
	
	var button_width = 200
	var button_height = 60
	var start_y = 350
	var spacing = 100
	
	for i in range(character_data.size()):
		var char = character_data[i]
		var button = Button.new()
		button.text = char["name"]
		button.custom_minimum_size = Vector2(button_width, button_height)
		button.anchor_left = 0.5
		button.anchor_top = 0.4
		button.offset_left = -button_width / 2
		button.offset_top = start_y + (i * spacing)
		button.modulate = char["color"]
		main_menu.add_child(button)
		
		# Подключаем сигнал
		button.pressed.connect(func(): _on_character_selected(char["type"]))

# ============================================================================
# Выбор персонажа
# ============================================================================

func _on_character_selected(character_type: String) -> void:
	"""Начинает игру с выбранным персонажем"""
	print("Выбран персонаж: %s" % character_type)
	
	if player:
		player.character_type = character_type
		player.setup_character()
	
	# Скрываем главное меню
	main_menu.visible = false
	
	# Создаём HUD
	create_hud()
	create_mobile_controls()
	
	# Соединяем сигналы
	if game_manager:
		game_manager.score_changed.connect(_on_score_changed)
		game_manager.wave_changed.connect(_on_wave_changed)
		game_manager.game_over.connect(_on_game_over)
	
	if player:
		player.health_changed.connect(_on_player_health_changed)
		player.level_up.connect(_on_player_level_up)
		player.experience_gained.connect(_on_experience_gained)

# ============================================================================
# HUD (Главный интерфейс во время игры)
# ============================================================================

func create_hud() -> void:
	"""Создаёт главный HUD во время игры"""
	
	hud_container = Control.new()
	hud_container.name = "HUD"
	hud_container.anchor_left = 0
	hud_container.anchor_top = 0
	hud_container.anchor_right = 1
	hud_container.anchor_bottom = 1
	add_child(hud_container)
	
	# ===== Верхняя левая часть: Здоровье и уровень =====
	health_label = Label.new()
	health_label.text = "HP: 100/100"
	health_label.add_theme_font_size_override("font_size", 24)
	health_label.anchor_left = 0
	health_label.anchor_top = 0
	health_label.offset_left = 20
	health_label.offset_top = 20
	hud_container.add_child(health_label)
	
	health_bar = ProgressBar.new()
	health_bar.value = 100
	health_bar.max_value = 100
	health_bar.custom_minimum_size = Vector2(300, 30)
	health_bar.anchor_left = 0
	health_bar.anchor_top = 0
	health_bar.offset_left = 20
	health_bar.offset_top = 50
	hud_container.add_child(health_bar)
	
	level_label = Label.new()
	level_label.text = "Уровень: 1"
	level_label.add_theme_font_size_override("font_size", 20)
	level_label.anchor_left = 0
	level_label.anchor_top = 0
	level_label.offset_left = 20
	level_label.offset_top = 85
	hud_container.add_child(level_label)
	
	xp_bar = ProgressBar.new()
	xp_bar.value = 0
	xp_bar.max_value = 100
	xp_bar.custom_minimum_size = Vector2(300, 20)
	xp_bar.anchor_left = 0
	xp_bar.anchor_top = 0
	xp_bar.offset_left = 20
	xp_bar.offset_top = 110
	hud_container.add_child(xp_bar)
	
	# ===== Верхний центр: Волна =====
	wave_label = Label.new()
	wave_label.text = "Волна: 1"
	wave_label.add_theme_font_size_override("font_size", 32)
	wave_label.anchor_left = 0.5
	wave_label.anchor_top = 0
	wave_label.offset_left = -80
	wave_label.offset_top = 20
	hud_container.add_child(wave_label)
	
	# ===== Верхний правый угол: Счёт =====
	score_label = Label.new()
	score_label.text = "Счёт: 0"
	score_label.add_theme_font_size_override("font_size", 28)
	score_label.anchor_left = 1
	score_label.anchor_top = 0
	score_label.offset_left = -200
	score_label.offset_top = 20
	hud_container.add_child(score_label)
	
	# ===== Кнопка паузы =====
	var pause_button = Button.new()
	pause_button.text = "⏸ ПАУЗА"
	pause_button.custom_minimum_size = Vector2(100, 40)
	pause_button.anchor_left = 1
	pause_button.anchor_top = 0
	pause_button.offset_left = -120
	pause_button.offset_top = 20
	pause_button.pressed.connect(func(): _on_pause_button_pressed())
	hud_container.add_child(pause_button)

# ============================================================================
# МОБИЛЬНЫЕ ЭЛЕМЕНТЫ УПРАВЛЕНИЯ
# ============================================================================

func create_mobile_controls() -> void:
	"""Создаёт кнопки управления для мобильных устройств"""
	
	var viewport_size = get_viewport_rect().size
	var button_size = 60
	var spacing = 10
	
	# ===== D-Pad (слева внизу) для движения =====
	mobile_d_pad = Control.new()
	mobile_d_pad.name = "DPad"
	mobile_d_pad.custom_minimum_size = Vector2(180, 180)
	mobile_d_pad.anchor_left = 0
	mobile_d_pad.anchor_bottom = 1
	mobile_d_pad.offset_left = 20
	mobile_d_pad.offset_top = -200
	hud_container.add_child(mobile_d_pad)
	
	# Кнопки D-Pad
	var dpad_buttons = [
		{"action": "ui_up", "position": Vector2(60, 10), "text": "↑"},
		{"action": "ui_down", "position": Vector2(60, 110), "text": "↓"},
		{"action": "ui_left", "position": Vector2(10, 60), "text": "←"},
		{"action": "ui_right", "position": Vector2(110, 60), "text": "→"}
	]
	
	for btn_data in dpad_buttons:
		var btn = Button.new()
		btn.text = btn_data["text"]
		btn.custom_minimum_size = Vector2(button_size, button_size)
		btn.position = btn_data["position"]
		btn.pressed.connect(func(): Input.action_press(btn_data["action"]))
		btn.released.connect(func(): Input.action_release(btn_data["action"]))
		mobile_d_pad.add_child(btn)
	
	# ===== Кнопки способностей (справа внизу) =====
	if player:
		var ability_count = player.active_abilities.size()
		var button_x_start = viewport_size.x - 300
		var button_y_start = viewport_size.y - 160
		
		for i in range(ability_count):
			var ability = player.active_abilities[i]
			var btn = Button.new()
			btn.text = "%s\n%s" % [ability["name"], str(i + 1)]
			btn.custom_minimum_size = Vector2(70, 70)
			btn.anchor_left = 1
			btn.anchor_bottom = 1
			btn.offset_left = button_x_start + (i * 80) - viewport_size.x
			btn.offset_top = button_y_start - viewport_size.y
			btn.pressed.connect(func(): _on_ability_button_pressed(i))
			hud_container.add_child(btn)
			ability_buttons.append(btn)

# ============================================================================
# CALLBACKS
# ============================================================================

func _on_score_changed(new_score: int) -> void:
	"""Обновляет отображение счёта"""
	if score_label:
		score_label.text = "Счёт: %d" % new_score

func _on_wave_changed(wave_number: int) -> void:
	"""Обновляет отображение волны"""
	if wave_label:
		wave_label.text = "Волна: %d" % wave_number

func _on_player_health_changed(current_health: int, max_hp: int) -> void:
	"""Обновляет отображение здоровья"""
	if health_label:
		health_label.text = "HP: %d/%d" % [current_health, max_hp]
	
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = current_health

func _on_player_level_up(new_level: int) -> void:
	"""Обновляет отображение уровня"""
	if level_label:
		level_label.text = "Уровень: %d" % new_level
	
	if xp_bar:
		xp_bar.value = 0

func _on_experience_gained(amount: int) -> void:
	"""Обновляет полоску опыта"""
	if player and xp_bar:
		xp_bar.value = player.experience

func _on_pause_button_pressed() -> void:
	"""Обрабатывает нажатие кнопки паузы"""
	if game_manager:
		game_manager.toggle_pause()

func _on_ability_button_pressed(ability_index: int) -> void:
	"""Обрабатывает нажатие кнопки способности"""
	if player:
		player.activate_ability(ability_index)

func _on_game_over() -> void:
	"""Показывает экран конца игры"""
	create_game_over_screen()

# ============================================================================
# ЭКРАН КОНЦА ИГРЫ
# ============================================================================

func create_game_over_screen() -> void:
	"""Создаёт экран конца игры"""
	
	game_over_menu = Control.new()
	game_over_menu.name = "GameOverMenu"
	game_over_menu.anchor_left = 0
	game_over_menu.anchor_top = 0
	game_over_menu.anchor_right = 1
	game_over_menu.anchor_bottom = 1
	add_child(game_over_menu)
	
	# Полупрозрачный фон
	var bg = ColorRect.new()
	bg.color = Color.BLACK
	bg.color.a = 0.7
	bg.anchor_left = 0
	bg.anchor_top = 0
	bg.anchor_right = 1
	bg.anchor_bottom = 1
	game_over_menu.add_child(bg)
	
	# Заголовок
	var title = Label.new()
	title.text = "ИГРА ОКОНЧЕНА"
	title.add_theme_font_size_override("font_size", 60)
	title.anchor_left = 0.5
	title.anchor_top = 0.3
	title.offset_left = -300
	title.offset_top = 0
	game_over_menu.add_child(title)
	
	# Статистика
	if game_manager and player:
		var stats = Label.new()
		stats.text = "Волна: %d\nОчки: %d\nУровень: %d" % [
			game_manager.current_wave,
			game_manager.current_score,
			player.level
		]
		stats.add_theme_font_size_override("font_size", 32)
		stats.anchor_left = 0.5
		stats.anchor_top = 0.5
		stats.offset_left = -150
		stats.offset_top = 0
		game_over_menu.add_child(stats)
	
	# Кнопка перезапуска
	var restart_button = Button.new()
	restart_button.text = "ПЕРЕЗАПУСТИТЬ"
	restart_button.custom_minimum_size = Vector2(300, 60)
	restart_button.anchor_left = 0.5
	restart_button.anchor_top = 0.75
	restart_button.offset_left = -150
	restart_button.offset_top = 0
	restart_button.pressed.connect(func(): get_tree().reload_current_scene())
	game_over_menu.add_child(restart_button)

# ============================================================================
# Класс для кнопок касания
# ============================================================================

class TouchButton extends Button:
	var action_name: String = ""
	
	func _ready() -> void:
		pressed.connect(func(): Input.action_press(action_name))
		released.connect(func(): Input.action_release(action_name))
