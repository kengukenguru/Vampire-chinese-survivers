extends Node2D

class_name EnemySpawner

var enemies_container: Node2D
var enemy_types: Array[String] = ["juyuanqu", "yamaluki", "kitsune"]
var spawn_interval: float = 0.5
var spawn_timer: float = 0.0
var enemies_to_spawn: int = 0
var spawned_enemies: int = 0
var is_spawning: bool = false

func _ready() -> void:
	enemies_container = get_parent().get_node_or_null("Enemies")
	if not enemies_container:
		enemies_container = Node2D.new()
		enemies_container.name = "Enemies"
		get_parent().add_child(enemies_container)
	print("EnemySpawner инициализирован")

func _process(delta: float) -> void:
	if is_spawning:
		spawn_timer -= delta
		if spawn_timer <= 0 and spawned_enemies < enemies_to_spawn:
			spawn_random_enemy()
			spawn_timer = spawn_interval

func spawn_wave(enemy_count: int) -> void:
	enemies_to_spawn = enemy_count
	spawned_enemies = 0
	spawn_timer = 0.0
	is_spawning = true
	print("Волна начата: будет заспавнено %d врагов" % enemy_count)

func spawn_random_enemy() -> void:
	spawned_enemies += 1
	var enemy_type = enemy_types[randi() % enemy_types.size()]
	create_enemy(enemy_type)

func create_enemy(enemy_type: String) -> void:
	var enemy = Enemy.new()
	enemy.name = enemy_type
	enemy.enemy_type = enemy_type
	var spawn_pos = get_random_spawn_position()
	enemy.global_position = spawn_pos
	enemies_container.add_child(enemy)

func get_random_spawn_position() -> Vector2:
	var viewport_size = get_viewport_rect().size
	var margin = 100
	var side = randi() % 4
	match side:
		0:
			return Vector2(randf_range(0, viewport_size.x), -margin)
		1:
			return Vector2(randf_range(0, viewport_size.x), viewport_size.y + margin)
		2:
			return Vector2(-margin, randf_range(0, viewport_size.y))
		3:
			return Vector2(viewport_size.x + margin, randf_range(0, viewport_size.y))
	return Vector2.ZERO
