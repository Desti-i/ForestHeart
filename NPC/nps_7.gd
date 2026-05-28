extends CharacterBody2D

@export var npc_name: String = "Таинственный вампир"

@onready var animated_sprite = $AnimatedSprite2D

var player_nearby: bool = false
var dialog_open: bool = false
var showing_choice: bool = false
var game_over: bool = false
var boss_defeated: bool = false

var canvas_layer: CanvasLayer
var dialog_panel: PanelContainer
var name_label: Label
var dialog_label: Label
var choice_container: HBoxContainer
var choice_btn_1: Button
var choice_btn_2: Button

func _ready():
	_create_ui()
	if animated_sprite:
		animated_sprite.play("idle")
	
	var area = $DetectionArea
	if area:
		area.body_entered.connect(_on_body_entered)
		area.body_exited.connect(_on_body_exited)
	
	# 👇 ПОДКЛЮЧАЕМ СИГНАЛ
	GameState.final_boss_defeated_changed.connect(_on_boss_defeated)
	
	# Проверяем текущее состояние
	_update_boss_status()
	

func _on_boss_defeated():
	boss_defeated = true
	_update_boss_status()
	
	# 👇 ПОКАЗЫВАЕМ, ЧТО ВАМПИР ГОТОВ
	_show_ready_message()

func _show_ready_message():
	var lbl = Label.new()
	lbl.text = "🧛 Теперь я готов говорить! Подойди ко мне!"
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color.GREEN)
	lbl.add_theme_constant_override("outline_size", 2)
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.position = global_position + Vector2(-100, -80)
	lbl.z_index = 100
	get_tree().current_scene.add_child(lbl)
	
	var tween = create_tween()
	tween.tween_property(lbl, "modulate:a", 0.0, 3.0)
	tween.tween_callback(lbl.queue_free)

func _update_boss_status():
	boss_defeated = GameState.final_boss_defeated

func _create_ui():
	canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 10
	add_child(canvas_layer)

	dialog_panel = PanelContainer.new()
	# 👇 МЕНЯЕМ ПОЗИЦИЮ НА ЦЕНТР ЭКРАНА
	dialog_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	dialog_panel.offset_top = -150
	dialog_panel.offset_left = -300
	dialog_panel.offset_right = 300
	dialog_panel.offset_bottom = 150
	dialog_panel.visible = false
	canvas_layer.add_child(dialog_panel)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.0, 0.08, 0.95)
	style.border_color = Color(0.8, 0.0, 0.0)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 15
	style.corner_radius_top_right = 15
	style.corner_radius_bottom_left = 15
	style.corner_radius_bottom_right = 15
	style.content_margin_left = 20
	style.content_margin_top = 20
	style.content_margin_right = 20
	style.content_margin_bottom = 20
	dialog_panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	dialog_panel.add_child(vbox)

	name_label = Label.new()
	name_label.text = npc_name
	name_label.add_theme_color_override("font_color", Color(0.8, 0.0, 0.0))
	name_label.add_theme_font_size_override("font_size", 24)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)

	dialog_label = Label.new()
	dialog_label.add_theme_color_override("font_color", Color.WHITE)
	dialog_label.add_theme_font_size_override("font_size", 16)
	dialog_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	dialog_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialog_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(dialog_label)

	choice_container = HBoxContainer.new()
	choice_container.add_theme_constant_override("separation", 20)
	choice_container.visible = false
	vbox.add_child(choice_container)

	choice_btn_1 = Button.new()
	choice_btn_1.text = ""
	choice_btn_1.custom_minimum_size = Vector2(220, 50)
	choice_btn_1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choice_container.add_child(choice_btn_1)

	choice_btn_2 = Button.new()
	choice_btn_2.text = ""
	choice_btn_2.custom_minimum_size = Vector2(220, 50)
	choice_btn_2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choice_container.add_child(choice_btn_2)

func _input(event):
	if event.is_action_pressed("interact") and player_nearby and not dialog_open and not game_over:
		if boss_defeated:
			_open_dialog()
		else:
			_show_locked_message()

func _show_locked_message():
	var lbl = Label.new()
	lbl.text = "🔒 Вампир молчит... Сначала победи босса!"
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color.RED)
	lbl.add_theme_constant_override("outline_size", 2)
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.position = global_position + Vector2(-120, -60)
	lbl.z_index = 100
	get_tree().current_scene.add_child(lbl)
	
	var tween = create_tween()
	tween.tween_property(lbl, "modulate:a", 0.0, 2.0)
	tween.tween_callback(lbl.queue_free)

func _open_dialog():
	dialog_open = true
	dialog_label.text = "Спасибо за помощь, путник!\nТы убил босса, как я и просил.\n\nТеперь отдай мне сердце Священного Дерева.\nЯ щедро тебя награжу...\n\nЧто скажешь?"
	dialog_panel.visible = true
	
	await get_tree().create_timer(0.5).timeout
	_show_choice()

func _show_choice():
	showing_choice = true
	choice_container.visible = true

	for c in choice_btn_1.pressed.get_connections():
		choice_btn_1.pressed.disconnect(c["callable"])
	for c in choice_btn_2.pressed.get_connections():
		choice_btn_2.pressed.disconnect(c["callable"])

	choice_btn_1.text = "💀 Принять"
	choice_btn_2.text = "⚔️ Отказать"

	choice_btn_1.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	choice_btn_2.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))

	choice_btn_1.pressed.connect(_bad_ending)
	choice_btn_2.pressed.connect(_good_ending)

func _bad_ending():
	dialog_panel.visible = false
	game_over = true
	
	# Убиваем игрока
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.current_health = 0
		player.can_move = false
		player.set_physics_process(false)
	
	# Затемнение
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 500
	get_tree().current_scene.add_child(overlay)
	
	var tw = create_tween()
	tw.tween_property(overlay, "color:a", 1.0, 1.5)
	await tw.finished
	
	_show_ending(false)

func _good_ending():
	dialog_panel.visible = false
	game_over = true
	
	# Затемнение
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 500
	get_tree().current_scene.add_child(overlay)
	
	var tw = create_tween()
	tw.tween_property(overlay, "color:a", 1.0, 1.0)
	await tw.finished
	
	# Вампир исчезает
	queue_free()
	
	# Показываем хорошую концовку
	_show_ending(true)

func _show_ending(is_good: bool):
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	get_tree().current_scene.add_child(canvas)

	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(bg)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.custom_minimum_size = Vector2(700, 400)
	vbox.position = Vector2(-350, -200)
	vbox.add_theme_constant_override("separation", 20)
	canvas.add_child(vbox)

	if not is_good:
		var title = Label.new()
		title.text = "ПЛОХАЯ КОНЦОВКА"
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.add_theme_font_size_override("font_size", 42)
		title.add_theme_color_override("font_color", Color(0.8, 0.0, 0.0))
		title.add_theme_constant_override("outline_size", 3)
		title.add_theme_color_override("font_outline_color", Color.BLACK)
		vbox.add_child(title)

		var story = Label.new()
		story.text = "Ты отдал сердце вампиру.\n\nОн получил невероятную силу и поглотил\nсилу Священного Дерева.\n\nДеревня была уничтожена.\nЛес погрузился во тьму навсегда.\n\nТы стал соучастником гибели мира..."
		story.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		story.autowrap_mode = TextServer.AUTOWRAP_WORD
		story.custom_minimum_size = Vector2(650, 0)
		story.add_theme_font_size_override("font_size", 16)
		story.add_theme_color_override("font_color", Color(0.8, 0.6, 0.6))
		vbox.add_child(story)
	else:
		var title = Label.new()
		title.text = "ХОРОШАЯ КОНЦОВКА"
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.add_theme_font_size_override("font_size", 42)
		title.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
		title.add_theme_constant_override("outline_size", 3)
		title.add_theme_color_override("font_outline_color", Color.BLACK)
		vbox.add_child(title)

		var story = Label.new()
		story.text = "Ты отказался отдать сердце и убил вампира!\n\nСердце Священного Древа возвращено на место.\nДерево ожило и наполнило лес своей силой.\nДеревня процветает, жители счастливы.\n\nТы стал настоящим героем!"
		story.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		story.autowrap_mode = TextServer.AUTOWRAP_WORD
		story.custom_minimum_size = Vector2(650, 0)
		story.add_theme_font_size_override("font_size", 16)
		story.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6))
		vbox.add_child(story)

	var btn = Button.new()
	btn.text = "В главное меню"
	btn.custom_minimum_size = Vector2(220, 50)
	btn.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	btn.position = Vector2(-110, -60)
	btn.add_theme_font_size_override("font_size", 16)
	canvas.add_child(btn)

	btn.pressed.connect(func():
		get_tree().change_scene_to_file("res://menu/menu.tscn")
	)

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_nearby = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_nearby = false
		if dialog_open:
			dialog_panel.visible = false
