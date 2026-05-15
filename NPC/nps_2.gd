extends CharacterBody2D

@export var npc_name: String = "Вампир"

@onready var animated_sprite = $AnimatedSprite2D

var player_nearby: bool = false
var dialog_open: bool = false
var current_line: int = 0
var dialog_lines: Array = []
var showing_choice: bool = false

var canvas_layer: CanvasLayer
var dialog_panel: PanelContainer
var name_label: Label
var dialog_label: Label
var next_button: Button
var choice_container: HBoxContainer
var choice_btn_1: Button
var choice_btn_2: Button

func _ready():
	if not GameState.vampire_spawned:
		visible = false
		_set_collision_active(false)
		var area = $DetectionArea
		if area:
			area.monitoring = false
		return
	visible = true
	_setup()

func _setup():
	_set_collision_active(true)
	_create_ui()
	_update_dialog()
	var area = $DetectionArea
	if area:
		area.monitoring = true
		if not area.body_entered.is_connected(_on_body_entered):
			area.body_entered.connect(_on_body_entered)
		if not area.body_exited.is_connected(_on_body_exited):
			area.body_exited.connect(_on_body_exited)
	print("🧛 Вампир готов!")

func _set_collision_active(active: bool):
	set_collision_layer_value(1, active)
	set_collision_mask_value(1, active)
	var shape = $CollisionShape2D
	if shape:
		shape.disabled = not active

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
	style.bg_color = Color(0.05, 0.0, 0.05, 0.95)
	style.border_color = Color(0.8, 0.0, 0.0)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	dialog_panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	dialog_panel.add_child(vbox)

	name_label = Label.new()
	name_label.text = npc_name
	name_label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2))
	name_label.add_theme_font_size_override("font_size", 22)
	vbox.add_child(name_label)

	dialog_label = Label.new()
	dialog_label.add_theme_color_override("font_color", Color.WHITE)
	dialog_label.add_theme_font_size_override("font_size", 18)
	dialog_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(dialog_label)

	next_button = Button.new()
	next_button.text = "Далее →"
	next_button.custom_minimum_size = Vector2(120, 40)
	next_button.pressed.connect(_on_next_pressed)
	vbox.add_child(next_button)

	# Кнопки выбора
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

func _hide_choice() -> void:
	showing_choice = false
	choice_container.visible = false
	next_button.visible = true

func _update_dialog():
	match GameState.quest_vampire:
		GameState.QuestState.NOT_TAKEN:
			dialog_lines = [
				"Приветствую, странник...",
				"Я видел как тот злодей украл сердце дерева.",
				"Он побежал в лес орков.",
				"Эти проклятые орки мешают нам жить.",
				"Убей 10 орков, что мешают мне вернуться домой.",
				"Я покажу куда ушёл злодей и открою тебе данж.",
				"Согласен помочь?"
			]
		GameState.QuestState.ACTIVE:
			var left = GameState.goblins_needed - GameState.goblins_killed
			dialog_lines = [
				"Ты ещё не убил всех орков.",
				"Осталось уничтожить: " + str(left),
				"Возвращайся когда сделаешь дело."
			]
		GameState.QuestState.COMPLETED:
			dialog_lines = [
				"Ты справился! Орки больше не угрожают нам!",
				"Спасибо тебе герой!",
				"Как и обещал — вот ключ от второй локации.",
				"У первого босса есть иммунитет к мечу.",
				"Советую прокачать магию огня и получить магию лечения.",
				"Иди и стань сильнее!"
			]
		GameState.QuestState.HANDED_IN:
			dialog_lines = [
				"Ты настоящий герой!",
				"Вторая локация открыта для тебя.",
				"Возвращайся если понадобится помощь."
			]
		_:
			dialog_lines = ["Что тебе нужно?"]

func _input(event):
	if event.is_action_pressed("interact") and player_nearby and not dialog_open and visible:
		_open_dialog()
	if event.is_action_pressed("ui_cancel") and dialog_open:
		_close_dialog()

func _open_dialog():
	dialog_open = true
	current_line = 0
	_update_dialog()
	dialog_label.text = dialog_lines[current_line]
	next_button.visible = true
	choice_container.visible = false
	dialog_panel.visible = true
	if len(dialog_lines) == 1:
		next_button.text = "Закрыть"
	else:
		next_button.text = "Далее →"

func _close_dialog():
	dialog_open = false
	showing_choice = false
	dialog_panel.visible = false
	next_button.visible = true
	choice_container.visible = false

func _on_next_pressed():
	if showing_choice:
		return

	if current_line + 1 < len(dialog_lines):
		current_line += 1
		dialog_label.text = dialog_lines[current_line]

		# Последняя строка - показываем выбор
		if current_line == len(dialog_lines) - 1:
			if GameState.quest_vampire == GameState.QuestState.NOT_TAKEN:
				next_button.visible = false
				_show_choice(
					"✅ Принять квест",
					"❌ Отказать",
					func():
						GameState.start_vampire_quest()
						_show_notification("🧛 Квест принят! Убей 10 орков!", Color.ORANGE)
						_close_dialog(),
					func():
						dialog_label.text = "Жаль... Я надеялся на твою помощь.\nМожет передумаешь?"
						next_button.visible = true
						next_button.text = "Закрыть"
						GameState.change_reputation(-5)
				)
			elif GameState.quest_vampire == GameState.QuestState.COMPLETED:
				next_button.text = "Получить ключ"
			else:
				next_button.text = "Закрыть"
	else:
		# Последнее нажатие
		if GameState.quest_vampire == GameState.QuestState.COMPLETED:
			GameState.hand_in_vampire_quest()
			_show_notification("🗝️ ВТОРАЯ ЛОКАЦИЯ ОТКРЫТА! +500 EXP", Color.GREEN)
			_close_dialog()
			await get_tree().create_timer(2.0).timeout
			queue_free()
		else:
			_close_dialog()

func _show_notification(msg: String, color: Color):
	var lbl = Label.new()
	lbl.text = msg
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_constant_override("outline_size", 2)
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.position = Vector2(150, 100)
	lbl.z_index = 200
	get_tree().current_scene.add_child(lbl)
	var tw = create_tween()
	tw.tween_property(lbl, "modulate:a", 0.0, 3.0)
	tw.tween_callback(lbl.queue_free)

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_nearby = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_nearby = false
		if dialog_open:
			_close_dialog()

func activate():
	visible = true
	_set_collision_active(true)
	_create_ui()
	_update_dialog()
	var area = $DetectionArea
	if area:
		area.monitoring = true
		if not area.body_entered.is_connected(_on_body_entered):
			area.body_entered.connect(_on_body_entered)
		if not area.body_exited.is_connected(_on_body_exited):
			area.body_exited.connect(_on_body_exited)
	print("🧛 Вампир активирован!")
