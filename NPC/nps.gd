extends CharacterBody2D

@export var npc_name: String = "Старейшина"

@onready var animated_sprite = $AnimatedSprite2D

var current_line: int = 0
var player_nearby: bool = false
var dialog_open: bool = false

var canvas_layer: CanvasLayer
var dialog_panel: PanelContainer
var name_label: Label
var dialog_label: Label
var next_button: Button

# Диалоги в зависимости от состояния квеста
func _get_dialog_lines() -> Array[String]:
	# КОШКА: если квест активен или выполнен
	match GameState.quest_cat:
		GameState.QuestState.NOT_TAKEN:
			# Проверяем, выполнен ли квест с кабанами
			if GameState.quest_kill_boars == GameState.QuestState.HANDED_IN:
				return [
					"А, это ты! Рад тебя видеть!",
					"У меня есть ещё одна просьба к тебе...",
					"Старушка из соседнего дома потеряла свою кошку.",
					"Она сбежала куда-то в лес.",
					"EXP я тебе не дам, но старушка говорила, что",
					"угостит тебя чем-то особенным...",
					"Поможешь старушке? Просто так, от чистого сердца?"
				]
		GameState.QuestState.ACTIVE:
			return [
				"Ты ещё не нашёл кошку?",
				"Бедная старушка очень переживает.",
				"Поищи в лесу, она должна быть где-то там.",
				"Кошка любит гулять возле деревьев."
			]
		GameState.QuestState.COMPLETED:
			return [
				"Ты нашёл кошку?! Где она?",
				"Старушка будет так рада!",
				"Говорит, что приготовила для тебя награду.",
				"Открой меню (Q) и посмотри вкладку магии!"
			]
		GameState.QuestState.HANDED_IN:
			return [
				"Старушка очень благодарна тебе!",
				"Кошка теперь целыми днями дома.",
				"Говорят, она даже научила тебя какой-то магии?",
				"Вот это награда! А я ведь предупреждал, что EXP не дам!"
			]
	
	# КАБАНЫ: если квест с кабанами активен или новый
	match GameState.quest_kill_boars:
		GameState.QuestState.NOT_TAKEN:
			return [
				"Приветствую тебя, путник!",
				"В наших лесах развелось много диких кабанов...",
				"Они топчут поля и пугают жителей!",
				"Убей 10 кабанов и я щедро награжу тебя 300 EXP!",
				"Берёшься за это дело?"
			]
		GameState.QuestState.ACTIVE:
			var left = GameState.boars_needed - GameState.boars_killed
			return [
				"А, это снова ты!",
				"Как продвигается охота?",
				"Кабанов осталось убить: " + str(left),
				"Удачи, я жду тебя!"
			]
		GameState.QuestState.COMPLETED:
			return [
				"Чувствую запах крови кабанов от тебя...",
				"Ты справился! Все 10 кабанов убиты!",
				"Держи свою награду — 300 EXP!",
				"А теперь у меня к тебе ещё одна просьба...",
				"Старушке нужна помощь — найди её кошку."
			]
		GameState.QuestState.HANDED_IN:
			return [
				"Рад видеть тебя снова, герой!",
				"Благодаря тебе деревня спокойна.",
				"Кстати, старушка тебе наверное уже рассказала?",
				"Хорошую магию она знает... используй с умом!"
			]
	return ["Здравствуй!"]

func _ready():
	_create_ui()
	if animated_sprite:
		animated_sprite.play("idle")
	player_nearby = false
	await get_tree().process_frame
	_check_initial_player_in_zone()
	GameState.quest_updated.connect(_on_quest_updated)
	print("NPC готов!")

func _on_quest_updated() -> void:
	# Обновляем диалог если он открыт
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
	dialog_panel.offset_top = -200
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

	next_button = Button.new()
	next_button.text = "Далее →"
	next_button.custom_minimum_size = Vector2(120, 40)
	next_button.pressed.connect(_on_next_button_pressed)
	vbox.add_child(next_button)

func _open_dialog():
	dialog_open = true
	current_line = 0
	var lines = _get_dialog_lines()
	dialog_label.text = lines[current_line]
	if lines.size() == 1:
		next_button.text = "Закрыть"
	else:
		next_button.text = "Далее →"
	dialog_panel.visible = true

func _close_dialog():
	dialog_open = false
	dialog_panel.visible = false
	current_line = 0
	next_button.text = "Далее →"

func _on_next_button_pressed() -> void:
	var lines = _get_dialog_lines()
	
	# Последняя реплика - особые действия
	if current_line == lines.size() - 1:
		_handle_last_line()
		_close_dialog()
		return

	current_line += 1
	dialog_label.text = lines[current_line]

	if current_line == lines.size() - 1:
		# Меняем кнопку на последней реплике
		if GameState.quest_cat == GameState.QuestState.NOT_TAKEN and GameState.quest_kill_boars == GameState.QuestState.HANDED_IN:
			next_button.text = "Принять квест (кошка)"
		elif GameState.quest_kill_boars == GameState.QuestState.NOT_TAKEN:
			next_button.text = "Принять квест"
		elif GameState.quest_kill_boars == GameState.QuestState.COMPLETED:
			next_button.text = "Получить награду"
		elif GameState.quest_cat == GameState.QuestState.ACTIVE:
			next_button.text = "Найди кошку"
		elif GameState.quest_cat == GameState.QuestState.COMPLETED:
			next_button.text = "Получить награду (магия)"
		else:
			next_button.text = "Закрыть"

func _handle_last_line() -> void:
	# Проверяем кошачий квест (если он предложен)
	if GameState.quest_cat == GameState.QuestState.NOT_TAKEN and GameState.quest_kill_boars == GameState.QuestState.HANDED_IN:
		GameState.start_quest_cat()
		print("🐱 Квест принят! Найди кошку!")
		return
	
	# Проверяем сдачу кошачьего квеста
	if GameState.quest_cat == GameState.QuestState.COMPLETED:
		GameState.hand_in_quest_cat()
		print("💚 Магия лечения открыта! Загляни в меню (Q)")
		return
	
	# Квест на кабанов
	match GameState.quest_kill_boars:
		GameState.QuestState.NOT_TAKEN:
			GameState.start_quest_kill_boars()
			print("📜 Квест принят!")
		GameState.QuestState.COMPLETED:
			GameState.hand_in_quest_kill_boars()
			print("🎉 Награда получена!")
			# Принудительно открываем диалог снова для предложения кошки
			await get_tree().create_timer(0.5).timeout
			_open_dialog()
		_:
			_close_dialog()

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = true

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = false
		if dialog_open:
			_close_dialog()
