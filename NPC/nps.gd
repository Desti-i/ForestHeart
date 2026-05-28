extends CharacterBody2D

@export var npc_name: String = "Старейшина"

@onready var animated_sprite = $AnimatedSprite2D

var current_line: int = 0
var player_nearby: bool = false
var dialog_open: bool = false
var showing_choice: bool = false

var canvas_layer: CanvasLayer
var dialog_panel: PanelContainer
var name_label: Label
var dialog_label: Label
var next_button: Button
var choice_container: HBoxContainer
var choice_btn_1: Button
var choice_btn_2: Button

func _get_dialog_lines() -> Array[String]:
	# Приоритет у квеста на осмотр дерева
	match GameState.quest_tree_inspect:
		GameState.QuestState.NOT_TAKEN:
			if GameState.quest_kill_boars == GameState.QuestState.HANDED_IN:
				return [
					"А, это ты! Рад тебя видеть!",
					"У меня есть важное задание для тебя.",
					"За нашим лесом есть древнее Древо Жизни.",
					"Оно хранит великую силу.",
					"Сходи, осмотри его.",
					"И да, по дороге поищи кошку.",
					"Она часто убегает в лес от старушки",
					"Поищи её в нижней части леса и принеси мне",
					"Старшка будет очень благодарна тебе",
					"Но сразу скажу, награды не жди!",
					"Справишься?"
				]
		GameState.QuestState.ACTIVE:
			return [
				"Ты ещё не был у Древа?",
				"Оно находится за лесом, на поляне.",
				"Иди туда и осмотри его."
			]
		GameState.QuestState.COMPLETED:
			match GameState.quest_cat:
				GameState.QuestState.NOT_TAKEN:
					return [
						"Ты нашёл Древо? Молодец!",
						"Магия огня теперь с тобой.",
						"А теперь у меня есть ещё одна просьба...",
						"Старушка из соседнего дома потеряла свою кошку.",
						"Поможешь ей?"
					]
				_:
					return [
						"Древо осмотрено, магия огня теперь с тобой.",
						"Старушке тоже нужна помощь."
					]

	# Квест кошка
	match GameState.quest_cat:
		GameState.QuestState.NOT_TAKEN:
			if GameState.quest_tree_inspect == GameState.QuestState.COMPLETED:
				return [
					"Старушка из соседнего дома потеряла свою кошку.",
					"Поможешь ей найти?"
				]
		GameState.QuestState.ACTIVE:
			return [
				"Ты ещё не нашёл кошку?",
				"Поищи в лесу, она должна быть где-то там."
			]
		GameState.QuestState.COMPLETED:
			return [
				"Ты нашёл кошку?!",
				"Старушка будет так рада! Забери награду."
			]
		GameState.QuestState.HANDED_IN:
			return [
				"Старушка очень благодарна тебе!",
				"Говорят она даже научила тебя какой-то магии?"
			]

	# Квест кабаны
	match GameState.quest_kill_boars:
		GameState.QuestState.NOT_TAKEN:
			return [
				"Приветствую тебя, путник!",
				"В наших лесах развелось много диких кабанов...",
				"Убей 10 кабанов и я награжу тебя 300 EXP!",
				"Берёшься?"
			]
		GameState.QuestState.ACTIVE:
			var left = GameState.boars_needed - GameState.boars_killed
			return [
				"Кабанов осталось убить: " + str(left),
				"Удачи!"
			]
		GameState.QuestState.COMPLETED:
			return [
				"Ты справился! Держи награду — 300 EXP!",
				"А теперь у меня есть ещё одно задание..."
			]
		GameState.QuestState.HANDED_IN:
			return [
				"Рад видеть тебя снова, герой!",
				"Благодаря тебе деревня спокойна."
			]
	return ["Здравствуй, путник!"]

func _ready():
	_create_ui()
	if animated_sprite:
		animated_sprite.play("idle")
	player_nearby = false
	await get_tree().process_frame
	_check_initial_player_in_zone()
	GameState.quest_updated.connect(_on_quest_updated)

func _on_quest_updated() -> void:
	if dialog_open:
		_close_dialog()

func _check_initial_player_in_zone():
	var bodies = $DetectionArea.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("player"):
			player_nearby = false
			return
	player_nearby = false

func _input(event):
	if event.is_action_pressed("interact") and player_nearby and not dialog_open:
		_open_dialog()
	if event.is_action_pressed("ui_cancel") and dialog_open:
		_close_dialog()

func _create_ui():
	canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 10
	add_child(canvas_layer)

	dialog_panel = PanelContainer.new()
	dialog_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	dialog_panel.offset_top = -220
	dialog_panel.offset_left = 100
	dialog_panel.offset_right = -100
	dialog_panel.visible = false
	canvas_layer.add_child(dialog_panel)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.9)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = Color.WHITE
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 20
	style.content_margin_top = 15
	style.content_margin_right = 20
	style.content_margin_bottom = 15
	dialog_panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	dialog_panel.add_child(vbox)

	name_label = Label.new()
	name_label.text = npc_name
	name_label.add_theme_color_override("font_color", Color.YELLOW)
	name_label.add_theme_font_size_override("font_size", 22)
	vbox.add_child(name_label)

	dialog_label = Label.new()
	dialog_label.add_theme_color_override("font_color", Color.WHITE)
	dialog_label.add_theme_font_size_override("font_size", 18)
	dialog_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(dialog_label)

	# Кнопка "Далее"
	next_button = Button.new()
	next_button.text = "Далее →"
	next_button.custom_minimum_size = Vector2(120, 40)
	next_button.pressed.connect(_on_next_button_pressed)
	vbox.add_child(next_button)

	choice_container = HBoxContainer.new()
	choice_container.add_theme_constant_override("separation", 10)
	choice_container.visible = false
	vbox.add_child(choice_container)

	choice_btn_1 = Button.new()
	choice_btn_1.custom_minimum_size = Vector2(180, 44)
	choice_btn_1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choice_container.add_child(choice_btn_1)

	choice_btn_2 = Button.new()
	choice_btn_2.custom_minimum_size = Vector2(180, 44)
	choice_btn_2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choice_container.add_child(choice_btn_2)

func _show_choice(text1: String, text2: String, cb1: Callable, cb2: Callable) -> void:
	showing_choice = true
	next_button.visible = false
	choice_container.visible = true

	if choice_btn_1.pressed.is_connected(_dummy):
		pass
	for c in choice_btn_1.pressed.get_connections():
		choice_btn_1.pressed.disconnect(c["callable"])
	for c in choice_btn_2.pressed.get_connections():
		choice_btn_2.pressed.disconnect(c["callable"])

	choice_btn_1.text = text1
	choice_btn_2.text = text2
	choice_btn_1.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
	choice_btn_2.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))

	choice_btn_1.pressed.connect(func():
		_hide_choice()
		cb1.call()
	)
	choice_btn_2.pressed.connect(func():
		_hide_choice()
		cb2.call()
	)

func _dummy() -> void:
	pass

func _hide_choice() -> void:
	showing_choice = false
	choice_container.visible = false
	next_button.visible = true

func _open_dialog():
	dialog_open = true
	current_line = 0
	var lines = _get_dialog_lines()
	dialog_label.text = lines[current_line]
	next_button.text = "Далее →"
	next_button.visible = true
	choice_container.visible = false
	if lines.size() == 1:
		next_button.text = "Закрыть"
	dialog_panel.visible = true

func _close_dialog():
	dialog_open = false
	showing_choice = false
	dialog_panel.visible = false
	current_line = 0
	next_button.text = "Далее →"
	next_button.visible = true
	choice_container.visible = false

func _on_next_button_pressed() -> void:
	if showing_choice:
		return
	var lines = _get_dialog_lines()

	if current_line == lines.size() - 1:
		_handle_last_line()
		return

	current_line += 1
	dialog_label.text = lines[current_line]

	if current_line == lines.size() - 1:
		_show_last_line_button()

func _show_last_line_button() -> void:
	# Квест осмотр дерева 
	if GameState.quest_tree_inspect == GameState.QuestState.NOT_TAKEN and \
	   GameState.quest_kill_boars == GameState.QuestState.HANDED_IN:
		_show_choice(
			"✅ Осмотреть Древо",
			"❌ Отказать",
			func():
				GameState.start_quest_tree_inspect()
				_show_notification("🌳 Квест принят! Найди Древо за лесом!")
				_close_dialog(),
			func():
				dialog_label.text = "Жаль... Древо ждёт своего героя."
				next_button.visible = true
				choice_container.visible = false
				next_button.text = "Закрыть"
		)
		return

	# Квест кошка
	if GameState.quest_cat == GameState.QuestState.NOT_TAKEN and \
	   GameState.quest_tree_inspect == GameState.QuestState.COMPLETED:
		_show_choice(
			"✅ Помочь старушке",
			"❌ Отказать",
			func():
				GameState.start_quest_cat()
				_show_notification("🐱 Квест принят! Найди кошку!")
				_close_dialog(),
			func():
				dialog_label.text = "Ну что ж... старушка будет огорчена."
				next_button.visible = true
				choice_container.visible = false
				next_button.text = "Закрыть"
				GameState.change_reputation(-10)
		)
		return

	# Квест кошка - сдача
	if GameState.quest_cat == GameState.QuestState.COMPLETED:
		next_button.text = "Получить награду"
		return

	# Квест кабаны - предложение
	if GameState.quest_kill_boars == GameState.QuestState.NOT_TAKEN:
		_show_choice(
			"✅ Принять квест",
			"❌ Отказать",
			func():
				GameState.start_quest_kill_boars()
				_show_notification("📜 Квест принят! Убей 10 кабанов!")
				_close_dialog(),
			func():
				dialog_label.text = "Жаль... деревня нуждается в помощи."
				next_button.visible = true
				choice_container.visible = false
				next_button.text = "Закрыть"
				GameState.change_reputation(-5)
		)
		return

	# Квест кабаны - сдача
	if GameState.quest_kill_boars == GameState.QuestState.COMPLETED:
		next_button.text = "Получить награду"
		return

	next_button.text = "Закрыть"

func _handle_last_line() -> void:
	if GameState.quest_cat == GameState.QuestState.COMPLETED:
		GameState.hand_in_quest_cat()
		_show_notification("💚 Магия лечения открыта!")
		_close_dialog()
		return

	if GameState.quest_kill_boars == GameState.QuestState.COMPLETED:
		GameState.hand_in_quest_kill_boars()
		_show_notification("🎉 +300 EXP получено!")
		await get_tree().create_timer(0.5).timeout
		_open_dialog()
		return

	_close_dialog()

func _show_notification(msg: String) -> void:
	var lbl = Label.new()
	lbl.text = msg
	lbl.add_theme_color_override("font_color", Color.YELLOW)
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_constant_override("outline_size", 2)
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.position = Vector2(200, 80)
	lbl.z_index = 200
	get_tree().current_scene.add_child(lbl)
	var tw = create_tween()
	tw.tween_property(lbl, "modulate:a", 0.0, 2.5)
	tw.tween_callback(lbl.queue_free)

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = true

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = false
		if dialog_open:
			_close_dialog()
