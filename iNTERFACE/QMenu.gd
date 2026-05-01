extends Control

var exp_label: Label
var vbox: VBoxContainer

func _ready() -> void:
	var panel = Panel.new()
	panel.position = Vector2(350, 80)
	panel.size = Vector2(320, 420)
	add_child(panel)

	var title := Label.new()
	title.text = "⚔ Прокачка"
	title.position = Vector2(350, 88)
	title.custom_minimum_size = Vector2(320, 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color.YELLOW)
	add_child(title)

	exp_label = Label.new()
	exp_label.position = Vector2(350, 120)
	exp_label.custom_minimum_size = Vector2(320, 24)
	exp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	exp_label.text = "⭐ " + str(GameState.exp) + " EXP"
	exp_label.add_theme_font_size_override("font_size", 15)
	add_child(exp_label)

	vbox = VBoxContainer.new()
	vbox.position = Vector2(360, 152)
	vbox.custom_minimum_size = Vector2(300, 300)
	vbox.add_theme_constant_override("separation", 8)
	add_child(vbox)

	var hint := Label.new()
	hint.text = "[Q] закрыть"
	hint.position = Vector2(350, 492)
	hint.custom_minimum_size = Vector2(320, 20)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	hint.add_theme_font_size_override("font_size", 13)
	add_child(hint)

	GameState.exp_changed.connect(_on_exp_changed)
	GameState.sword_upgraded.connect(func(_l): refresh())
	GameState.fire_magic_upgraded.connect(func(_l): refresh())

func _on_exp_changed(amount: int) -> void:
	if exp_label:
		exp_label.text = "⭐ " + str(amount) + " EXP"

func refresh() -> void:
	exp_label.text = "⭐ " + str(GameState.exp) + " EXP"
	for child in vbox.get_children():
		child.queue_free()

	# ── Секция меча ───────────────────────────────────────
	_add_section_title("⚔ МЕЧ  [Пробел]")

	for i in GameState.sword_levels.size():
		var sw = GameState.sword_levels[i]

		if i < GameState.sword_level:
			continue  # пропускаем старые уровни

		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(300, 50)
		row.add_theme_constant_override("separation", 8)
		vbox.add_child(row)

		var color_rect := ColorRect.new()
		color_rect.custom_minimum_size = Vector2(6, 50)
		color_rect.color = sw["color"]
		row.add_child(color_rect)

		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)

		var name_lbl := Label.new()
		var dmg_lbl  := Label.new()

		if i == GameState.sword_level:
			name_lbl.text = "▶ " + sw["description"]
			dmg_lbl.text  = "Урон: " + str(sw["damage"]) + "  [ТЕКУЩИЙ]"
			name_lbl.add_theme_color_override("font_color", sw["color"])
			dmg_lbl.add_theme_color_override("font_color", Color.WHITE)
		else:
			name_lbl.text = "🔒 " + sw["description"]
			dmg_lbl.text  = "Урон: " + str(sw["damage"]) + "  |  " + str(sw["cost"]) + " EXP"
			name_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			dmg_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))

		name_lbl.add_theme_font_size_override("font_size", 14)
		dmg_lbl.add_theme_font_size_override("font_size", 12)
		info.add_child(name_lbl)
		info.add_child(dmg_lbl)

		if i == GameState.sword_level + 1:
			var btn := Button.new()
			btn.text = "Улучшить"
			btn.custom_minimum_size = Vector2(80, 44)
			var idx = i
			btn.pressed.connect(func():
				if GameState.upgrade_sword():
					refresh()
				else:
					_show_hint("❌ Нужно " + str(GameState.sword_levels[idx]["cost"]) + " EXP!")
			)
			row.add_child(btn)

	# ── Разделитель ───────────────────────────────────────
	vbox.add_child(HSeparator.new())

	# ── Секция магии огня ─────────────────────────────────
	_add_section_title("🔥 МАГИЯ ОГНЯ  [F]")

	if GameState.fire_magic_level == 0:
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(300, 50)
		vbox.add_child(row)

		var color_rect := ColorRect.new()
		color_rect.custom_minimum_size = Vector2(6, 50)
		color_rect.color = Color(0.8, 0.3, 0.0)
		row.add_child(color_rect)

		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)

		var lbl1 := Label.new()
		lbl1.text = "🔒 Магия огня не открыта"
		lbl1.add_theme_font_size_override("font_size", 14)
		lbl1.add_theme_color_override("font_color", Color(0.8, 0.5, 0.2))
		var lbl2 := Label.new()
		lbl2.text = "Открыть за 50 EXP"
		lbl2.add_theme_font_size_override("font_size", 12)
		info.add_child(lbl1)
		info.add_child(lbl2)

		var btn := Button.new()
		btn.text = "Открыть"
		btn.custom_minimum_size = Vector2(80, 44)
		btn.pressed.connect(func():
			if GameState.upgrade_fire_magic():
				refresh()
			else:
				_show_hint("❌ Нужно 50 EXP!")
		)
		row.add_child(btn)
	else:
		for i in range(1, GameState.fire_magic_levels.size()):
			# Показываем только текущий и следующий
			if i < GameState.fire_magic_level:
				continue
			if i > GameState.fire_magic_level + 1:
				continue
			
			var fm = GameState.fire_magic_levels[i]
			var row := HBoxContainer.new()
			row.custom_minimum_size = Vector2(300, 50)
			row.add_theme_constant_override("separation", 8)
			vbox.add_child(row)

			var color_rect := ColorRect.new()
			color_rect.custom_minimum_size = Vector2(6, 50)
			color_rect.color = fm["color"]
			row.add_child(color_rect)

			var info := VBoxContainer.new()
			info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(info)

			var name_lbl := Label.new()
			var dmg_lbl  := Label.new()

			if i == GameState.fire_magic_level:
				name_lbl.text = "▶ " + fm["description"]
				dmg_lbl.text  = "Урон: " + str(fm["damage"]) + "  [ТЕКУЩИЙ]"
				name_lbl.add_theme_color_override("font_color", fm["color"])
				dmg_lbl.add_theme_color_override("font_color", Color.WHITE)
			else:
				name_lbl.text = "🔒 " + fm["description"]
				dmg_lbl.text  = "Урон: " + str(fm["damage"]) + "  |  " + str(fm["cost"]) + " EXP"
				name_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
				dmg_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))

			name_lbl.add_theme_font_size_override("font_size", 14)
			dmg_lbl.add_theme_font_size_override("font_size", 12)
			info.add_child(name_lbl)
			info.add_child(dmg_lbl)

			if i == GameState.fire_magic_level + 1:
				var btn := Button.new()
				btn.text = "Улучшить"
				btn.custom_minimum_size = Vector2(80, 44)
				var idx = i
				btn.pressed.connect(func():
					if GameState.upgrade_fire_magic():
						refresh()
					else:
						_show_hint("❌ Нужно " + str(GameState.fire_magic_levels[idx]["cost"]) + " EXP!")
				)
				row.add_child(btn)

func _add_section_title(text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	vbox.add_child(lbl)

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
