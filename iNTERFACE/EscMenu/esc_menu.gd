extends CanvasLayer

@onready var menu_root = $Control

func _ready():
	# Прячем меню при запуске
	menu_root.hide()

func _input(event):
	if event.is_action_pressed("menu"):
		toggle_pause()

func toggle_pause():
	var is_paused = !get_tree().paused
	get_tree().paused = is_paused
	
	if is_paused:
		menu_root.show()
	else:
		menu_root.hide()
		
func _on_resume_btn_pressed() -> void:
	toggle_pause()

func _on_save_btn_pressed() -> void:
	GameState.update_save_data()

func _on_option_btn_pressed() -> void:
	pass # Replace with function body.

func _on_quit_btn_pressed() -> void:
	GameState.update_save_data()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://menu/menu.tscn")
