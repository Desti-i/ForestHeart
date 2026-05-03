extends Node2D
# ─── Спавнер врагов ───────────────────────────────────────
# Добавь этот узел на карту, настрой сцену врага и таймер.
# Враг спавнится в радиусе spawn_radius от позиции Spawner.
#
# Структура:
#   Spawner (Node2D) + Spawner.gd
#     └─ Timer (переименуй в "SpawnTimer")

## Сцена врага которого спавним — укажи в Инспекторе
@export var enemy_scene: PackedScene

## Максимум живых врагов от этого спавнера одновременно
@export var max_enemies: int = 3

## Через сколько СЕКУНД спавнить (300 = 5 минут)
@export var spawn_interval: float = 300.0

## Радиус в котором появляется враг (вокруг позиции Spawner)
@export var spawn_radius: float = 60.0

## Показывать отладочный круг в редакторе
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
	print("🌀 Spawner готов. Интервал:", spawn_interval, "сек. Макс врагов:", max_enemies)

func _on_timer_timeout() -> void:
	print("⏰ Спавнер: прошло ", spawn_interval, " сек — спавним новых врагов!")
	_spawn_wave()

func _spawn_wave() -> void:
	# Чистим мёртвых из списка
	_alive_enemies = _alive_enemies.filter(func(e): return is_instance_valid(e))

	var need = max_enemies - _alive_enemies.size()
	if need <= 0:
		print("🔴 Спавнер: уже ", _alive_enemies.size(), " живых, пропускаем")
		return

	for i in need:
		_spawn_one()

func _spawn_one() -> void:
	if enemy_scene == null:
		print("❌ Spawner: enemy_scene не назначена!")
		return

	# Случайная позиция в радиусе
	var angle = randf() * TAU
	var dist  = randf_range(20.0, spawn_radius)
	var pos   = global_position + Vector2(cos(angle), sin(angle)) * dist

	var enemy = enemy_scene.instantiate()
	enemy.global_position = pos

	# Передаём спавн-позицию для патруля
	if enemy.has_method("_ready"):
		# spawn_position установится в _ready врага автоматически
		pass

	get_parent().add_child(enemy)
	_alive_enemies.append(enemy)
	print("✅ Спавнер: создан враг в позиции ", pos)

## Показываем радиус спавна в редакторе
func _draw() -> void:
	if show_debug and Engine.is_editor_hint():
		draw_circle(Vector2.ZERO, spawn_radius, Color(1, 0.3, 0.3, 0.2))
		draw_arc(Vector2.ZERO, spawn_radius, 0, TAU, 32, Color(1, 0.3, 0.3, 0.6), 2.0)
