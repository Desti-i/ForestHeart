extends Control

var exp_label: Label
var vbox: VBoxContainer

func _ready() -> void:
	# Панель
	var panel = Panel.new()
	panel.position = Vector2(350, 80)
	panel.size = Vector2(320, 320)
	add_child(panel)

	# Заголовок
	var title := Label.new()
	title.text = "⚔ Прокачка меча"
	title.position = Vector2(350, 88)
	title.custom_minimum_size = Vector2(320, 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color.YELLOW)
	add_child(title)

	# EXP
	exp_label = Label.new()
	exp_label.position = Vector2(350, 120)
	exp_label.custom_minimum_size = Vector2(320, 24)
	exp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	exp_label.text = "⭐ " + str(GameState.exp) + " EXP"
	exp_label.add_theme_font_size_override("font_size", 15)
	add_child(exp_label)

	# Кнопки
	vbox = VBoxContainer.new()
	vbox.position = Vector2(360, 152)
	vbox.custom_minimum_size = Vector2(300, 200)
	vbox.add_theme_constant_override("separation", 8)
	add_child(vbox)

	# Подсказка
	var hint := Label.new()
	hint.text = "[Q] закрыть"
	hint.position = Vector2(350, 390)
	hint.custom_minimum_size = Vector2(320, 20)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	hint.add_theme_font_size_override("font_size", 13)
	add_child(hint)

	GameState.exp_changed.connect(_on_exp_changed)
	GameState.sword_upgraded.connect(func(_l): refresh())

func _on_exp_changed(amount: int) -> void:
	if exp_label:
		exp_label.text = "⭐ " + str(amount) + " EXP"

func refresh() -> void:
	exp_label.text = "⭐ " + str(GameState.exp) + " EXP"

	for child in vbox.get_children():
		child.queue_free()

	for i in GameState.sword_levels.size():
		var sw = GameState.sword_levels[i]

		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(300, 60)
		row.add_theme_constant_override("separation", 8)
		vbox.add_child(row)

		# Цветной индикатор уровня
		var color_rect := ColorRect.new()
		color_rect.custom_minimum_size = Vector2(8, 60)
		color_rect.color = sw["color"]
		row.add_child(color_rect)

		# Контейнер текста и кнопки
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)

		# Название и описание
		var name_lbl := Label.new()
		var damage_lbl := Label.new()

		if i < GameState.sword_level:
			name_lbl.text = "✅ " + sw["description"]
			damage_lbl.text = "Урон: " + str(sw["damage"])
			name_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
			damage_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		elif i == GameState.sword_level:
			name_lbl.text = "▶ " + sw["description"]
			damage_lbl.text = "Урон: " + str(sw["damage"]) + "  [ТЕКУЩИЙ]"
			name_lbl.add_theme_color_override("font_color", sw["color"])
			damage_lbl.add_theme_color_override("font_color", Color.WHITE)
		else:
			name_lbl.text = "🔒 " + sw["description"]
			damage_lbl.text = "Урон: " + str(sw["damage"]) + "  |  Цена: " + str(sw["cost"]) + " EXP"
			name_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			damage_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))

		name_lbl.add_theme_font_size_override("font_size", 15)
		damage_lbl.add_theme_font_size_override("font_size", 13)
		info.add_child(name_lbl)
		info.add_child(damage_lbl)

		# Кнопка улучшения (только для следующего уровня)
		if i == GameState.sword_level + 1:
			var btn := Button.new()
			btn.text = "Улучшить"
			btn.custom_minimum_size = Vector2(80, 50)
			var idx = i
			btn.pressed.connect(func():
				if GameState.upgrade_sword():
					refresh()
				else:
					_show_hint("❌ Нужно " + str(GameState.sword_levels[idx]["cost"]) + " EXP!")
			)
			row.add_child(btn)

	# Разделитель
	var sep := HSeparator.new()
	vbox.add_child(sep)

	# Будущее оружие
	var future := Label.new()
	future.text = "🗡 Другое оружие: выпадает с боссов"
	future.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	future.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	future.add_theme_font_size_override("font_size", 13)
	vbox.add_child(future)

func _show_hint(msg: String) -> void:
	var lbl := Label.new()
	lbl.text = msg
	lbl.position = Vector2(360, 62)
	lbl.add_theme_color_override("font_color", Color.RED)
	lbl.add_theme_font_size_override("font_size", 15)
	add_child(lbl)
	var tween = create_tween()
	tween.tween_property(lbl, "modulate:a", 0.0, 1.5)
	tween.tween_callback(lbl.queue_free)
