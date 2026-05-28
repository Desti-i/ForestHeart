extends Node2D
# ─── Локация 2 ──────────────────────────
@onready var player = $Player           
@onready var spawn_points: Dictionary = {}  

func _ready() -> void:
	
	if GameState.is_respawning:
		GameState.is_respawning = false
		return
	
	if SaveManager.has_save_file():
		GameState.apply_load_data()
	
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
