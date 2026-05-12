extends Node2D

func _ready():
	await get_tree().process_frame
	
	if SaveManager.has_save_file():
		GameState.apply_load_data()
