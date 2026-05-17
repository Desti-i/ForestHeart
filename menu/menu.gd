extends CanvasLayer

func _on_game_pressed() -> void:
	if SaveManager.has_save_file():
		SaveManager.load_game()
		
		var saved_scene = SaveManager.game_data.current_scene
		get_tree().change_scene_to_file(saved_scene)
	else:
		get_tree().change_scene_to_file("res://locations/primary_village/Vilage1.tscn")


func _on_new_game_pressed() -> void:
	SaveManager.game_data = {
	"current_scene": "res://locations/primary_village/Vilage1.tscn",
	"player_pos": {"x": 0, "y": 0},
	"stats": {
		"exp": 0,
		"current_health": 100,
		"sword_level": 0,
		"fire_magic_level": 0,
		"water_magic_level": 0,
		"heal_magic_level": 0
	},
	"quests": {
		"quest_kill_boars": {
			"state": 0,
			"progress": 0
		},
		"cat_quest": {
			"state": 0,
			"progress": {"cat_found": false, "heal_magic_unlocked": false}
		}
	}
}
	
	SaveManager.save_game()

	get_tree().change_scene_to_file("res://locations/primary_village/Vilage1.tscn")


func _on_exit_pressed() -> void:
		get_tree().quit()
