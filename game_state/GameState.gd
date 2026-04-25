extends Node

# ─── Глобальное состояние игры ───────────────────────────
# Этот файл — автозагрузка (Autoload).
# В Project > Project Settings > Autoload добавь:
#   Путь: res://game_state/GameState.gd
#   Имя:  GameState

## Есть ли у игрока ключ от портала (дропается с босса)
var has_boss_key: bool = false

## Точка появления игрока на локации 2 (имя маркера SpawnPoint)
var spawn_point_name: String = "SpawnPoint"

func _ready() -> void:
	print("✅ GameState загружен. has_boss_key =", has_boss_key)
