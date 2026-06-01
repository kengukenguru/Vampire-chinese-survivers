extends CharacterBody2D

class_name Enemy

signal died(enemy: Enemy, position: Vector2)
signal took_damage(damage: float)

var enemy_type: String = "juyuanqu"
var health: float = 10.0
var max_health: float = 10.0
var speed: float = 150.0
var damage: float = 5.0
var attack_range: float = 30.0
var attack_cooldown: float = 1.0
var attack_timer: float = 0.0
var experience_reward: int = 10
var target: Node2D
var target_distance: float = 0.0
var is_alive: bool = true

func _ready() -> void:
	setup_enemy_type()
	target = get_tree().root.get_node_or_null("Game/Player")
	if not target:
		print("ОШИБКА: Игрок не найден для врага %s" % enemy_type)
		queue_free()
		return
	health = max_health
	print("Враг %s создан (HP: %.0f, Damage: %.0f)" % [enemy_type, health, damage])

func _process(delta: float) -> void:
	if not is_alive or not target:
		return
	var direction_to_target = (target.global_position - global_position).normalized()
	target_distance = global_position.distance_to(target.global_position)
	velocity = direction_to_target * speed
	move_and_slide()
	if attack_timer > 0:
		attack_timer -= delta
	if target_distance <= attack_range and attack_timer <= 0:
		attack_player()

func setup_enemy_type() -> void:
	match enemy_type:
		"juyuanqu":
			max_health = 10.0
			health = 10.0
			speed = 180.0
			damage = 5.0
		"yamaluki":
			max_health = 25.0
			health = 25.0
			speed = 120.0
			damage = 12.0
		"kitsune":
			max_health = 15.0
			health = 15.0
			speed = 200.0
			damage = 8.0

func attack_player() -> void:
	if target and target.has_method("take_damage"):
		target.take_damage(damage)
		attack_timer = attack_cooldown

func take_damage(damage_amount: float) -> void:
	health -= damage_amount
	took_damage.emit(damage_amount)
	if health <= 0:
		die()

func die() -> void:
	if not is_alive:
		return
	is_alive = false
	if target and target.has_method("gain_experience"):
		target.gain_experience(experience_reward)
	died.emit(self, global_position)
	queue_free()
