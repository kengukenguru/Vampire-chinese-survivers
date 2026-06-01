extends CanvasLayer

class_name UIManager

var game_manager: Node2D
var player: Node2D
var main_menu: Control
var hud_container: Control
var health_label: Label
var health_bar: ProgressBar
var score_label: Label
var wave_label: Label
var level_label: Label
var xp_bar: ProgressBar
var ability_buttons: Array[Button] = []

func _ready() -> void:
	game_manager = get_tree().root.get_node_or_null("Game")
	player = get_tree().root.get_node_or_null("Game/Player")
	create_main_menu()
	print("UIManager инициализирован")

func create_main_menu() -> void:
	main_menu = Control.new()
	main_menu.name = "MainMenu"
	main_menu.anchor_left = 0
	main_menu.anchor_top = 0
	main_menu.anchor_right = 1
	main_menu.anchor_bottom = 1
	add_child(main_menu)
	
	var title = Label.new()
	title.text = "VAMPIRE CHINESE SURVIVORS"
	title.add_theme_font_size_override("font_size", 48)
	title.anchor_left = 0.5
	title.anchor_top = 0.1
	title.offset_left = -300
	title.offset_top = 0
	main_menu.add_child(title)
	
	var character_data = [
		{"name": "Боевой Монах", "type": "monk"},
		{"name": "Даосский Маг", "type": "mage"},
		{"name": "Воин-Демон", "type": "demon_warrior"},
		{"name": "Дух Лисы", "type": "fox_spirit"}
	]
	
	for i in range(character_data.size()):
		var char = character_data[i]
		var button = Button.new()
		button.text = char["name"]
		button.custom_minimum_size = Vector2(200, 60)
		button.anchor_left = 0.5
		button.anchor_top = 0.4
		button.offset_left = -100
		button.offset_top = 350 + (i * 100)
		main_menu.add_child(button)
		button.pressed.connect(func(): _on_character_selected(char["type"]))

func _on_character_selected(character_type: String) -> void:
	print("Выбран персонаж: %s" % character_type)
	if player:
		player.character_type = character_type
		player.setup_character()
	main_menu.visible = false
	create_hud()
	
	if game_manager:
		game_manager.score_changed.connect(_on_score_changed)
		game_manager.wave_changed.connect(_on_wave_changed)
		game_manager.game_over.connect(_on_game_over)
	
	if player:
		player.health_changed.connect(_on_player_health_changed)
		player.level_up.connect(_on_player_level_up)
		player.experience_gained.connect(_on_experience_gained)

func create_hud() -> void:
	hud_container = Control.new()
	hud_container.name = "HUD"
	hud_container.anchor_left = 0
	hud_container.anchor_top = 0
	hud_container.anchor_right = 1
	hud_container.anchor_bottom = 1
	add_child(hud_container)
	
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
	
	wave_label = Label.new()
	wave_label.text = "Волна: 1"
	wave_label.add_theme_font_size_override("font_size", 32)
	wave_label.anchor_left = 0.5
	wave_label.anchor_top = 0
	wave_label.offset_left = -80
	wave_label.offset_top = 20
	hud_container.add_child(wave_label)
	
	score_label = Label.new()
	score_label.text = "Счёт: 0"
	score_label.add_theme_font_size_override("font_size", 28)
	score_label.anchor_left = 1
	score_label.anchor_top = 0
	score_label.offset_left = -200
	score_label.offset_top = 20
	hud_container.add_child(score_label)

func _on_score_changed(new_score: int) -> void:
	if score_label:
		score_label.text = "Счёт: %d" % new_score

func _on_wave_changed(wave_number: int) -> void:
	if wave_label:
		wave_label.text = "Волна: %d" % wave_number

func _on_player_health_changed(current_health: int, max_hp: int) -> void:
	if health_label:
		health_label.text = "HP: %d/%d" % [current_health, max_hp]
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = current_health

func _on_player_level_up(new_level: int) -> void:
	if level_label:
		level_label.text = "Уровень: %d" % new_level

func _on_experience_gained(amount: int) -> void:
	pass

func _on_game_over() -> void:
	print("Игра окончена!")
