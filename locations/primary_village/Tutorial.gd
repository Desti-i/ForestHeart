extends CanvasLayer

func _ready():
	if GameState.tutorial_completed:
		queue_free()
		return
	
	_show_welcome()

func _show_welcome():
	# Полупрозрачный фон
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.size = get_viewport().size
	overlay.position = Vector2(0, 0)
	overlay.z_index = 498
	add_child(overlay)
	
	# Панель
	var panel = Panel.new()
	panel.size = Vector2(550, 430)
	panel.position = Vector2((get_viewport().size.x - 550) / 2, (get_viewport().size.y - 430) / 2)
	panel.z_index = 500
	add_child(panel)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12, 0.95)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.7, 0.6, 0.3)
	style.corner_radius_top_left = 15
	style.corner_radius_top_right = 15
	style.corner_radius_bottom_left = 15
	style.corner_radius_bottom_right = 15
	panel.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.size = Vector2(510, 390)
	vbox.position = Vector2(20, 20)
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)
	
	# Заголовок
	var title = Label.new()
	title.text = "🌳 ДОБРО ПОЖАЛОВАТЬ 🌳"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	# Описание
	var desc = Label.new()
	desc.text = "Эта деревня берёт свою силу от таинственного Древа Жизни.\nЕго сердце хранит мощь, которая питает эти земли."
	desc.add_theme_font_size_override("font_size", 14)
	desc.add_theme_color_override("font_color", Color.WHITE)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(desc)
	
	# Разделитель
	var sep1 = HSeparator.new()
	vbox.add_child(sep1)
	
	# Подзаголовок управления
	var controls_title = Label.new()
	controls_title.text = "УПРАВЛЕНИЕ"
	controls_title.add_theme_font_size_override("font_size", 18)
	controls_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	controls_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(controls_title)
	
	# Сетка управления
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 30)
	grid.add_theme_constant_override("v_separation", 8)
	vbox.add_child(grid)
	
	var controls = [
		["[E]", "взаимодействие"],
		["[Q]", "меню"],
		["[Пробел]", "атака мечом"],
		["[Shift]", "бег"],
		["[Ctrl]", "рывок"]
	]
	
	for c in controls:
		var key = Label.new()
		key.text = c[0]
		key.add_theme_font_size_override("font_size", 16)
		key.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
		grid.add_child(key)
		
		var action = Label.new()
		action.text = c[1]
		action.add_theme_font_size_override("font_size", 16)
		action.add_theme_color_override("font_color", Color.WHITE)
		grid.add_child(action)
	
	# Разделитель
	var sep2 = HSeparator.new()
	vbox.add_child(sep2)
	
	# Задание
	var quest = Label.new()
	quest.text = "Начни с разговора со Старейшиной.\nОн расскажет тебе больше о Древе и даст первое задание."
	quest.add_theme_font_size_override("font_size", 14)
	quest.add_theme_color_override("font_color", Color.WHITE)
	quest.autowrap_mode = TextServer.AUTOWRAP_WORD
	quest.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(quest)
	
	# Вопрос
	var question = Label.new()
	question.text = "Готов ли ты приступить к игре?"
	question.add_theme_font_size_override("font_size", 16)
	question.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	question.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(question)
	
	# Кнопка
	var button = Button.new()
	button.text = "ГОТОВ"
	button.custom_minimum_size = Vector2(200, 45)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_size_override("font_size", 18)
	button.pressed.connect(_on_tutorial_close.bind(overlay, panel))
	vbox.add_child(button)

func _on_tutorial_close(overlay: ColorRect, panel: Panel):
	overlay.queue_free()
	panel.queue_free()
	GameState.tutorial_completed = true
	queue_free()
