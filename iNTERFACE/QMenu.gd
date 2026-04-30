extends Control
# ─── Q Меню — создаёт всё само, не нужны дочерние узлы ──
# Просто прикрепи этот скрипт к Control узлу QMenu
# и добавь QMenu внутрь CanvasLayer

var exp_label: Label
var vbox: VBoxContainer
var panel: Panel

func _ready() -> void:
	# Создаём панель фона
	panel = Panel.new()
	panel.position = Vector2(400, 100)
	panel.size = Vector2(300, 380)
	add_child(panel)

	# Заголовок
	var title := Label.new()
	title.text = "⚔ Меню оружий"
	title.position = Vector2(410, 108)
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color.YELLOW)
	add_child(title)

	# EXP метка
	exp_label = Label.new()
	exp_label.position = Vector2(410, 135)
	exp_label.text = "⭐ " + str(GameState.exp) + " EXP"
	exp_label.add_theme_font_size_override("font_size", 15)
	add_child(exp_label)

	# Подсказка закрыть
	var hint := Label.new()
	hint.text = "[Q] закрыть"
	hint.position = Vector2(410, 455)
	hint.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	hint.add_theme_font_size_override("font_size", 13)
	add_child(hint)

	# Контейнер для кнопок
	vbox = VBoxContainer.new()
	vbox.position = Vector2(410, 160)
	vbox.size = Vector2(280, 280)
	add_child(vbox)

	GameState.exp_changed.connect(_on_exp_changed)

func _on_exp_changed(amount: int) -> void:
	if exp_label:
		exp_label.text = "⭐ " + str(amount) + " EXP"

func refresh() -> void:
	exp_label.text = "⭐ " + str(GameState.exp) + " EXP"

	for child in vbox.get_children():
		child.queue_free()

	for i in GameState.weapons.size():
		var w = GameState.weapons[i]
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(270, 45)

		if w["unlocked"]:
			if i == GameState.active_weapon_index:
				btn.text = "✅ " + w["name"] + "  (урон: " + str(w["damage"]) + ")"
			else:
				btn.text = "⚔ " + w["name"] + "  (урон: " + str(w["damage"]) + ")"
		else:
			btn.text = "🔒 " + w["name"] + "  — " + str(w["cost"]) + " EXP"

		btn.add_theme_font_size_override("font_size", 15)
		var idx = i
		btn.pressed.connect(func():
			if GameState.weapons[idx]["unlocked"]:
				GameState.select_weapon(idx)
				refresh()
			else:
				if GameState.unlock_weapon(idx):
					GameState.select_weapon(idx)
					refresh()
				else:
					_show_hint("❌ Не хватает EXP!")
		)
		vbox.add_child(btn)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	var magic_lbl := Label.new()
	magic_lbl.text = "🔮 Магия — скоро..."
	magic_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 1.0))
	magic_lbl.add_theme_font_size_override("font_size", 15)
	vbox.add_child(magic_lbl)

func _show_hint(msg: String) -> void:
	var lbl := Label.new()
	lbl.text = msg
	lbl.position = Vector2(410, 90)
	lbl.add_theme_color_override("font_color", Color.RED)
	lbl.add_theme_font_size_override("font_size", 16)
	add_child(lbl)
	var tween = create_tween()
	tween.tween_property(lbl, "modulate:a", 0.0, 1.5)
	tween.tween_callback(lbl.queue_free)
