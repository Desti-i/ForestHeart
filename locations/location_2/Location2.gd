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
	if GameState.is_respawning:
		GameState.is_respawning = false
		return
	
	if SaveManager.has_save_file():
		GameState.apply_load_data()
	
	# Собираем все Marker2D — точки спауна
	for child in get_children():
		if child is Marker2D:
			spawn_points[child.name] = child

	if SaveManager.has_save_file() and SaveManager.game_data.current_scene == scene_file_path:
		var saved_pos = SaveManager.game_data.player_pos
		if saved_pos.x != 0 or saved_pos.y != 0:
			player.global_position = Vector2(saved_pos.x, saved_pos.y)
			return

	# Телепортируем игрока к нужной точке
	var target_name = GameState.spawn_point_name
	if target_name in spawn_points:
		player.global_position = spawn_points[target_name].global_position
		print("✅ Игрок заспавнен в:", target_name, spawn_points[target_name].global_position)
	else:
		print("⚠️ SpawnPoint '", target_name, "' не найден, игрок остался на месте")

	print("🗺️ Локация 2 загружена!")
