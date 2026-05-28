extends Node2D
# ─── Спавнер врагов ───────────────────────────────────────

@export var enemy_scene: PackedScene

# Максимум живых врагов 
@export var max_enemies: int = 3

# Через сколько спавнить 
@export var spawn_interval: float = 300.0

# Радиус в котором появляется враг 
@export var spawn_radius: float = 60.0

@export var show_debug: bool = true

var _alive_enemies: Array = []
var _timer: Timer

func _ready() -> void:
	# Создаём таймер
	_timer = Timer.new()
	_timer.wait_time  = spawn_interval
	_timer.autostart  = true
	_timer.one_shot   = false
	_timer.timeout.connect(_on_timer_timeout)
	add_child(_timer)

	# Спавним сразу при старте
	await get_tree().process_frame
	_spawn_wave()

func _on_timer_timeout() -> void:
	_spawn_wave()

func _spawn_wave() -> void:
	# Чистим мёртвых из списка
	_alive_enemies = _alive_enemies.filter(func(e): return is_instance_valid(e))

	var need = max_enemies - _alive_enemies.size()
	if need <= 0:
		return

	for i in need:
		_spawn_one()

func _spawn_one() -> void:
	if enemy_scene == null:
		return

	# Случайная позиция в радиусе
	var angle = randf() * TAU
	var dist  = randf_range(20.0, spawn_radius)
	var pos   = global_position + Vector2(cos(angle), sin(angle)) * dist

	var enemy = enemy_scene.instantiate()
	enemy.global_position = pos

	# Передаём спавн-позицию для патруля
	if enemy.has_method("_ready"):
		pass

	get_parent().add_child(enemy)
	_alive_enemies.append(enemy)

func _draw() -> void:
	if show_debug and Engine.is_editor_hint():
		draw_circle(Vector2.ZERO, spawn_radius, Color(1, 0.3, 0.3, 0.2))
		draw_arc(Vector2.ZERO, spawn_radius, 0, TAU, 32, Color(1, 0.3, 0.3, 0.6), 2.0)
