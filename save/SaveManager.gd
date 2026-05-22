extends Node

const SAVE_PATH = "user://savegame.json"

var game_data = {
	"current_scene": "res://locations/primary_village/Vilage1.tscn",
	"player_pos": {"x": 0, "y": 0},
	"stats": {
		"exp": 0,
		"current_health": 100,
		"max_health": 100,
		
		"sword_level": 0,
		"sword_lvl3_dropped": false,
		"fire_sword_unlocked": false,
		"fire_sword_level": 0,
		
		"fire_magic_level": 0,
		
		"water_magic_level": 0,
		"water_magic_unlocked": false,
		
		"ice_magic_unlocked": false,
		"ice_magic_level": 0,
		
		"blood_magic_unlocked": false,
		"blood_magic_level": 1,
		
		"heal_magic_unlocked": false,
		"heal_magic_level": 0
		
	},
	"quests": {
		"quest_kill_boars": {
			"state": 0,
			"progress": 0
		},
		"cat_quest": {
			"state": 0,
			"progress": false
		},
		"quest_vampire": {
			"state": 0,
			"progress": false
		},
		"quest_tree_inspect": {
			"state": 0,
			"progress": false
		}
	},
	"flags": {
		"tree_intro_shown": false,
		"monster_encounter_triggered": false,
		"tree_heart_stolen": false,
		"vampire_spawned": false,
		"second_location_unlocked": false
	},
	"opened_doors": {}
}

func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

# Функция сохранения данных на диск
func save_game():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	
	if file == null:
		print("Ошибка открытия файла для записи: ", FileAccess.get_open_error())
		return

	var json_string = JSON.stringify(game_data, "\t")
	
	file.store_line(json_string)
	file.close()
	print("Игра успешно сохранена в: ", OS.get_user_data_dir())

# Функция загрузки данных с диска
func load_game():
	if not FileAccess.file_exists(SAVE_PATH):
		print("Файл сохранения не найден. Используются начальные значения.")
		return
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	
	if file == null:
		print("Ошибка открытия файла для чтения.")
		return

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_string)
	
	if error == OK:
		game_data = json.data
		print("Игра успешно загружена!")
		print(game_data.player_pos.x)
		print(game_data.player_pos.y)
	else:
		print("Ошибка парсинга JSON: ", json.get_error_message())
