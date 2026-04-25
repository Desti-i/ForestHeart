extends Node2D
# ─── Локация 2 (базовый скрипт) ──────────────────────────
# Прикрепи к корневому узлу сцены Location2.tscn
#
# Структура сцены Location2.tscn:
#   Location2 (Node2D)         ← этот скрипт
#     ├─ TileMap                ← твоя карта локации 2
#     ├─ Player (CharacterBody2D) ← instanced из player/Player.tscn
#     ├─ SpawnPoint (Marker2D) ← точка появления игрока
#     ├─ CanvasLayer
#     │    └─ Control (UI)
#     └─ ... враги, боссы, NPC

@onready var player = $Player           # путь к игроку в сцене
@onready var spawn_points: Dictionary = {}  # имя → Marker2D

func _ready() -> void:
	# Собираем все Marker2D — точки спауна
	for child in get_children():
		if child is Marker2D:
			spawn_points[child.name] = child

	# Телепортируем игрока к нужной точке
	var target_name = GameState.spawn_point_name
	if target_name in spawn_points:
		player.global_position = spawn_points[target_name].global_position
		print("✅ Игрок заспавнен в:", target_name, spawn_points[target_name].global_position)
	else:
		print("⚠️ SpawnPoint '", target_name, "' не найден, игрок остался на месте")

	print("🗺️ Локация 2 загружена!")
