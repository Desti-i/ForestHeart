extends Node2D

func _ready():
	await get_tree().process_frame
	
	if GameState.is_respawning:
		GameState.is_respawning = false
		return
		
	if SaveManager.has_save_file():
		GameState.apply_load_data()
