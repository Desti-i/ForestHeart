extends Control

var exp_label: Label
var vbox: VBoxContainer
var current_tab: String = "weapon"

var tab_weapon_btn: Button
var tab_magic_btn: Button
var tab_quest_btn: Button

func _ready() -> void:
	GameState.water_magic_upgraded.connect(func(_l): refresh())
	GameState.water_magic_unlocked_signal.connect(func(): refresh())
	GameState.active_magic_changed.connect(func(_t): refresh())
	GameState.exp_changed.connect(_on_exp_changed)
	GameState.sword_upgraded.connect(func(_l): refresh())
	GameState.fire_magic_upgraded.connect(func(_l): refresh())

	# Панель
	var panel = Panel.new()
	panel.position = Vector2(300, 50)
	panel.size = Vector2(420, 580)
	add_child(panel)

	# Заголовок
	var title := Label.new()
	title.text = "📋 Меню"
	title.position = Vector2(300, 58)
	title.custom_minimum_size = Vector2(420, 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color.YELLOW)
	add_child(title)

	# EXP
	exp_label = Label.new()
	exp_label.position = Vector2(300, 90)
	exp_label.custom_minimum_size = Vector2(420, 24)
	exp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	exp_label.text = "⭐ " + str(GameState.exp) + " EXP"
	exp_label.add_theme_font_size_override("font_size", 14)
	add_child(exp_label)

	# Вкладки
	var tab_bar := HBoxContainer.new()
	tab_bar.position = Vector2(308, 118)
	tab_bar.custom_minimum_size = Vector2(404, 36)
	tab_bar.add_theme_constant_override("separation", 4)
	add_child(tab_bar)

	tab_weapon_btn = _make_tab_btn("⚔ Оружие", "weapon")
	tab_magic_btn  = _make_tab_btn("🔥 Магия",  "magic")
	tab_quest_btn  = _make_tab_btn("📜 Квесты", "quest")
	tab_weapon_btn.custom_minimum_size = Vector2(130, 34)
	tab_magic_btn.custom_minimum_size  = Vector2(130, 34)
	tab_quest_btn.custom_minimum_size  = Vector2(130, 34)
	tab_bar.add_child(tab_weapon_btn)
	tab_bar.add_child(tab_magic_btn)
	tab_bar.add_child(tab_quest_btn)

	# ScrollContainer для контента
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(308, 158)
	scroll.custom_minimum_size = Vector2(404, 440)
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(400, 0)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 6)
	scroll.add_child(vbox)

	# Подсказка - теперь ниже скролла
	var hint := Label.new()
	hint.text = "[Q] закрыть"
	hint.position = Vector2(300, 600)
	hint.custom_minimum_size = Vector2(420, 20)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	hint.add_theme_font_size_override("font_size", 13)
	add_child(hint)

func _make_tab_btn(text: String, tab: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.pressed.connect(func():
		current_tab = tab
		_update_tab_colors()
		refresh()
	)
	return btn

func _update_tab_colors() -> void:
	for pair in [[tab_weapon_btn, "weapon"], [tab_magic_btn, "magic"], [tab_quest_btn, "quest"]]:
		var btn = pair[0]
		var tab = pair[1]
		if tab == current_tab:
			btn.add_theme_color_override("font_color", Color.YELLOW)
		else:
			btn.remove_theme_color_override("font_color")

func _on_exp_changed(amount: int) -> void:
	if exp_label:
		exp_label.text = "⭐ " + str(amount) + " EXP"

func refresh() -> void:
	if exp_label:
		exp_label.text = "⭐ " + str(GameState.exp) + " EXP"
	for child in vbox.get_children():
		child.queue_free()
	_update_tab_colors()
	match current_tab:
		"weapon": _draw_weapon_tab()
		"magic":  _draw_magic_tab()
		"quest":  _draw_quest_tab()

# ══════════════════════════════════════════════════════════
# ВКЛАДКА: ОРУЖИЕ
# ══════════════════════════════════════════════════════════
func _draw_weapon_tab() -> void:
	_add_section_title("⚔ МЕЧ  [Пробел]")

	for i in GameState.sword_levels.size():
		if i < GameState.sword_level: continue
		if i > GameState.sword_level + 1: continue

		var sw  = GameState.sword_levels[i]
		var row = _make_row()

		var cr = _make_color_bar(sw["color"])
		row.add_child(cr)

		var info = _make_info_box()
		row.add_child(info)

		var name_lbl = _make_label("", 14)
		var dmg_lbl  = _make_label("", 12)

		if i == GameState.sword_level:
			name_lbl.text = "▶ " + sw["description"]
			dmg_lbl.text  = "Урон: " + str(sw["damage"]) + "  [ТЕКУЩИЙ]"
			name_lbl.add_theme_color_override("font_color", sw["color"])
			dmg_lbl.add_theme_color_override("font_color", Color.WHITE)
		else:
			name_lbl.text = "🔒 " + sw["description"]
			dmg_lbl.text  = "Урон: " + str(sw["damage"]) + "  |  " + str(sw["cost"]) + " EXP"
			name_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
			dmg_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))

		info.add_child(name_lbl)
		info.add_child(dmg_lbl)

		if i == GameState.sword_level + 1:
			var idx = i
			row.add_child(_make_upgrade_btn(func():
				if GameState.upgrade_sword():
					refresh()
				else:
					_show_hint("❌ Нужно " + str(GameState.sword_levels[idx]["cost"]) + " EXP!")
			))

		vbox.add_child(row)

	vbox.add_child(HSeparator.new())
	var future = _make_label("🗡 Другое оружие: выпадает с боссов", 13)
	future.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	future.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	vbox.add_child(future)

# ══════════════════════════════════════════════════════════
# ВКЛАДКА: МАГИЯ
# ══════════════════════════════════════════════════════════
func _draw_magic_tab() -> void:
	_add_section_title("✨ АКТИВНАЯ МАГИЯ  [F]")

	var select_row := HBoxContainer.new()
	select_row.custom_minimum_size = Vector2(390, 40)
	select_row.add_theme_constant_override("separation", 6)
	vbox.add_child(select_row)

	# Кнопка огня
	var fire_btn := Button.new()
	fire_btn.text = "🔥 Огонь"
	fire_btn.custom_minimum_size = Vector2(188, 36)
	fire_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if GameState.active_magic == "fire":
		fire_btn.add_theme_color_override("font_color", Color(1.0, 0.5, 0.0))
	if GameState.fire_magic_level > 0:
		fire_btn.pressed.connect(func():
			GameState.set_active_magic("fire")
			refresh()
		)
	else:
		fire_btn.disabled = true
	select_row.add_child(fire_btn)

	# Кнопка воды
	var water_btn := Button.new()
	water_btn.text = "💧 Вода" if GameState.water_magic_unlocked else "💧 Вода 🔒"
	water_btn.custom_minimum_size = Vector2(188, 36)
	water_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if GameState.active_magic == "water":
		water_btn.add_theme_color_override("font_color", Color(0.2, 0.7, 1.0))
	if GameState.water_magic_unlocked:
		water_btn.pressed.connect(func():
			GameState.set_active_magic("water")
			refresh()
		)
	else:
		water_btn.disabled = true
	select_row.add_child(water_btn)

	vbox.add_child(HSeparator.new())

	# ── Огонь ─────────────────────────────────────────────
	_add_section_title("🔥 МАГИЯ ОГНЯ")

	if GameState.fire_magic_level == 0:
		var row = _make_row()
		row.add_child(_make_color_bar(Color(0.8, 0.3, 0.0)))
		var info = _make_info_box()
		info.add_child(_make_colored_label("🔒 Магия огня не открыта", 14, Color(0.8, 0.5, 0.2)))
		info.add_child(_make_label("Открыть за 50 EXP", 12))
		row.add_child(info)
		row.add_child(_make_upgrade_btn(func():
			if GameState.upgrade_fire_magic():
				GameState.set_active_magic("fire")
				refresh()
			else:
				_show_hint("❌ Нужно 50 EXP!"),
			"Открыть"
		))
		vbox.add_child(row)
	else:
		for i in range(1, GameState.fire_magic_levels.size()):
			if i < GameState.fire_magic_level: continue
			if i > GameState.fire_magic_level + 1: continue
			var fm  = GameState.fire_magic_levels[i]
			var row = _make_row()
			row.add_child(_make_color_bar(fm["color"]))
			var info = _make_info_box()
			var name_lbl = _make_label("", 14)
			var dmg_lbl  = _make_label("", 12)
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
			info.add_child(name_lbl)
			info.add_child(dmg_lbl)
			row.add_child(info)
			if i == GameState.fire_magic_level + 1:
				var idx = i
				row.add_child(_make_upgrade_btn(func():
					if GameState.upgrade_fire_magic():
						refresh()
					else:
						_show_hint("❌ Нужно " + str(GameState.fire_magic_levels[idx]["cost"]) + " EXP!")
				))
			vbox.add_child(row)

	vbox.add_child(HSeparator.new())

	# ── Вода ──────────────────────────────────────────────
	_add_section_title("💧 МАГИЯ ВОДЫ")

	if not GameState.water_magic_unlocked:
		var row = _make_row()
		row.add_child(_make_color_bar(Color(0.2, 0.4, 0.8)))
		var info = _make_info_box()
		info.add_child(_make_colored_label("🔒 Не получена", 14, Color(0.4, 0.6, 1.0)))
		info.add_child(_make_colored_label("Выпадает с водных мобов", 12, Color(0.6, 0.6, 0.6)))
		row.add_child(info)
		vbox.add_child(row)
	else:
		for i in range(1, GameState.water_magic_levels.size()):
			if i < GameState.water_magic_level: continue
			if i > GameState.water_magic_level + 1: continue
			var wm  = GameState.water_magic_levels[i]
			var row = _make_row()
			row.add_child(_make_color_bar(wm["color"]))
			var info = _make_info_box()
			var name_lbl = _make_label("", 14)
			var dmg_lbl  = _make_label("", 12)
			if i == GameState.water_magic_level:
				name_lbl.text = "▶ " + wm["description"]
				dmg_lbl.text  = "Урон: " + str(wm["damage"]) + "  [ТЕКУЩИЙ]"
				name_lbl.add_theme_color_override("font_color", wm["color"])
				dmg_lbl.add_theme_color_override("font_color", Color.WHITE)
			else:
				name_lbl.text = "🔒 " + wm["description"]
				dmg_lbl.text  = "Урон: " + str(wm["damage"]) + "  |  " + str(wm["cost"]) + " EXP"
				name_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
				dmg_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			info.add_child(name_lbl)
			info.add_child(dmg_lbl)
			row.add_child(info)
			if i == GameState.water_magic_level + 1:
				var idx = i
				row.add_child(_make_upgrade_btn(func():
					if GameState.upgrade_water_magic():
						refresh()
					else:
						_show_hint("❌ Нужно " + str(GameState.water_magic_levels[idx]["cost"]) + " EXP!")
				))
			vbox.add_child(row)

# ══════════════════════════════════════════════════════════
# ВКЛАДКА: КВЕСТЫ
# ══════════════════════════════════════════════════════════
func _draw_quest_tab() -> void:
	_add_section_title("📜 КВЕСТЫ")

	var quests = [
		{"name": "Убить орков",      "desc": "Убей 5 орков в лесу",        "done": false},
		{"name": "Найти старейшину", "desc": "Поговори с NPC в деревне",    "done": true},
	]

	for q in quests:
		var row = _make_row()
		row.add_child(_make_color_bar(Color.GREEN if q["done"] else Color(0.5, 0.5, 0.5)))
		var info = _make_info_box()
		var name_lbl = _make_label(("✅ " if q["done"] else "🔲 ") + q["name"], 14)
		name_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5) if q["done"] else Color.WHITE)
		var desc_lbl = _make_colored_label(q["desc"], 12, Color(0.7, 0.7, 0.7))
		info.add_child(name_lbl)
		info.add_child(desc_lbl)
		row.add_child(info)
		vbox.add_child(row)

# ══════════════════════════════════════════════════════════
# ХЕЛПЕРЫ
# ══════════════════════════════════════════════════════════
func _make_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(390, 52)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 6)
	return row

func _make_color_bar(color: Color) -> ColorRect:
	var cr := ColorRect.new()
	cr.custom_minimum_size = Vector2(5, 52)
	cr.color = color
	return cr

func _make_info_box() -> VBoxContainer:
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return info

func _make_label(text: String, size: int) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", size)
	lbl.clip_text = true
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return lbl

func _make_colored_label(text: String, size: int, color: Color) -> Label:
	var lbl = _make_label(text, size)
	lbl.add_theme_color_override("font_color", color)
	return lbl

func _make_upgrade_btn(callback: Callable, label: String = "Улучшить") -> Button:
	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = Vector2(82, 48)
	btn.pressed.connect(callback)
	return btn

func _add_section_title(text: String) -> void:
	var lbl = _make_colored_label(text, 15, Color(0.9, 0.9, 0.9))
	vbox.add_child(lbl)

func _show_hint(msg: String) -> void:
	var lbl := Label.new()
	lbl.text = msg
	lbl.position = Vector2(308, 42)
	lbl.custom_minimum_size = Vector2(404, 20)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color", Color.RED)
	lbl.add_theme_font_size_override("font_size", 15)
	add_child(lbl)
	var tween = create_tween()
	tween.tween_property(lbl, "modulate:a", 0.0, 1.5)
	tween.tween_callback(lbl.queue_free)
