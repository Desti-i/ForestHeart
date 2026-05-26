extends Area2D

@export var next_scene: String = "res://locations/Location3.tscn"

var player_nearby: bool = false

func _ready():
	print("🟣 ПОРТАЛ ЗАПУЩЕН!")
	
	# Отключаем старые сигналы, если они есть
	if body_entered.is_connected(_on_body_entered):
		body_entered.disconnect(_on_body_entered)
	if body_exited.is_connected(_on_body_exited):
		body_exited.disconnect(_on_body_exited)
	
	# Подключаем сигналы
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Обновляем внешний вид
	_update_portal_appearance()

func _update_portal_appearance():
	if GameState.boss_defeated:
		modulate = Color(1, 1, 1, 1)
		print("✅ Портал АКТИВЕН!")
	else:
		modulate = Color(0.3, 0.3, 0.5, 0.5)
		print("🔒 Портал ЗАКРЫТ! Нужно убить босса.")

func _on_body_entered(body: Node2D):
	if body.is_in_group("player"):
		GameState.update_save_data()
		player_nearby = true
		if GameState.boss_defeated:
			_show_hint("🌀 Нажми E для перехода!", Color.CYAN)
		else:
			_show_hint("🔒 Победи босса!", Color.RED)

func _on_body_exited(body: Node2D):
	if body.is_in_group("player"):
		player_nearby = false

func _input(event):
	if event.is_action_pressed("interact") and player_nearby and GameState.boss_defeated:
		_teleport()

func _teleport():
	print("🌀 Телепортация!")
	
	# Эффект затемнения
	var rect = ColorRect.new()
	rect.color = Color(0, 0, 0, 0)
	rect.size = get_viewport().size
	rect.z_index = 1000
	get_tree().current_scene.add_child(rect)
	
	var tween = create_tween()
	tween.tween_property(rect, "color:a", 1.0, 0.3)
	await tween.finished
	
	# Переход на следующую сцену
	get_tree().change_scene_to_file(next_scene)

func _show_hint(msg: String, color: Color):
	var lbl = Label.new()
	lbl.text = msg
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_constant_override("outline_size", 2)
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.position = global_position + Vector2(-80, -60)
	lbl.z_index = 100
	get_tree().current_scene.add_child(lbl)
	
	var tween = create_tween()
	tween.tween_property(lbl, "modulate:a", 0.0, 2.0)
	tween.tween_callback(lbl.queue_free)
