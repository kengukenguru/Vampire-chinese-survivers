extends CharacterBody2D

class_name Player

signal health_changed(new_health: int, max_health: int)
signal level_up(new_level: int)
signal ability_activated(ability_name: String)
signal experience_gained(amount: int)

var character_type: String = "monk"
var health: int = 100
var max_health: int = 100
var experience: int = 0
var level: int = 1
var armor: float = 0.0
var speed: float = 200.0
var direction: Vector2 = Vector2.ZERO
var acceleration: float = 800.0
var base_damage: float = 10.0
var touch_position: Vector2 = Vector2.ZERO
var is_touch_moving: bool = false

var sprite: Sprite2D
var collision: CollisionShape2D
var active_abilities: Array[Dictionary] = []
var passive_bonuses: Array[Dictionary] = []
var active_ability_cooldowns: Dictionary = {}

func _ready() -> void:
	setup_character()
	sprite = get_node_or_null("Sprite2D")
	collision = get_node_or_null("CollisionShape2D")
	health = max_health
	print("Персонаж %s инициализирован (HP: %d, Speed: %.1f)" % [character_type, health, speed])

func setup_character() -> void:
	match character_type:
		"monk":
			setup_monk()
		"mage":
			setup_mage()
		"demon_warrior":
			setup_demon_warrior()
		"fox_spirit":
			setup_fox_spirit()

func setup_monk() -> void:
	max_health = 80
	health = 80
	speed = 280
	base_damage = 8.0
	active_abilities = [{"name": "quick_strike", "damage": 15, "cooldown": 1.5}]

func setup_mage() -> void:
	max_health = 120
	health = 120
	speed = 150
	base_damage = 12.0
	active_abilities = [{"name": "fireball", "damage": 40, "cooldown": 2.0}]

func setup_demon_warrior() -> void:
	max_health = 100
	health = 100
	speed = 200
	base_damage = 11.0
	active_abilities = [{"name": "demon_slash", "damage": 25, "cooldown": 1.8}]

func setup_fox_spirit() -> void:
	max_health = 90
	health = 90
	speed = 260
	base_damage = 9.0
	active_abilities = [{"name": "fox_fire", "damage": 20, "cooldown": 1.5}]

func _process(delta: float) -> void:
	update_direction()
	apply_movement(delta)
	update_ability_cooldowns(delta)

func update_direction() -> void:
	direction = Vector2.ZERO
	if Input.is_action_pressed("ui_right"):
		direction.x += 1
	if Input.is_action_pressed("ui_left"):
		direction.x -= 1
	if Input.is_action_pressed("ui_down"):
		direction.y += 1
	if Input.is_action_pressed("ui_up"):
		direction.y -= 1
	if direction.length() > 0:
		direction = direction.normalized()

func apply_movement(delta: float) -> void:
	var target_velocity = direction * speed
	velocity = velocity.lerp(target_velocity, acceleration * delta)
	move_and_slide()
	clamp_position_to_screen()

func clamp_position_to_screen() -> void:
	var viewport_rect = get_viewport_rect()
	var sprite_size = 32
	global_position.x = clamp(global_position.x, sprite_size, viewport_rect.size.x - sprite_size)
	global_position.y = clamp(global_position.y, sprite_size, viewport_rect.size.y - sprite_size)

func take_damage(damage: float) -> void:
	var reduced_damage = damage * (1.0 - (armor / 100.0))
	health -= int(reduced_damage)
	if sprite:
		sprite.modulate = Color.RED
		await get_tree().create_timer(0.1).timeout
		sprite.modulate = Color.WHITE
	health_changed.emit(health, max_health)

func heal(amount: int) -> void:
	health = min(health + amount, max_health)
	health_changed.emit(health, max_health)

func gain_experience(amount: int) -> void:
	experience += amount
	experience_gained.emit(amount)
	var xp_for_next_level = 100 * level
	if experience >= xp_for_next_level:
		level_up_player()

func level_up_player() -> void:
	level += 1
	experience = 0
	max_health += 20
	health = max_health
	base_damage += 2.0
	print("Уровень повышен до %d!" % level)
	level_up.emit(level)

func update_ability_cooldowns(delta: float) -> void:
	for ability_name in active_ability_cooldowns.keys():
		active_ability_cooldowns[ability_name] -= delta
