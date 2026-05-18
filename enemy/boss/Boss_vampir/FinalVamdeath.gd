extends State

func enter():
	enemy.set_physics_process(false)
	enemy.velocity = Vector2.ZERO
	enemy.animP.stop()

	enemy.get_node("CollisionShape2D").set_deferred("disabled", true)

	if enemy.has_node("Attack_zone"):
		enemy.get_node("Attack_zone").set_deferred("disabled", true)
	if enemy.has_node("Attack_area"):
		enemy.get_node("Attack_area").set_deferred("monitoring", false)

	GameState.add_exp(enemy.exp_reward)
	GameState.heart_returned = true
	GameState.current_ending = GameState.Ending.GOOD

	# Анимация смерти
	var anim_name = "death_" + enemy.get_direction_string()
	if enemy.anim.sprite_frames.has_animation(anim_name):
		enemy.anim.play(anim_name)
		await enemy.anim.animation_finished
	else:
		await enemy.get_tree().create_timer(1.0).timeout

	# Эффект исчезновения
	var tw = enemy.create_tween()
	tw.tween_property(enemy, "modulate:a", 0.0, 1.0)
	await tw.finished

	enemy.queue_free()

	# Показываем хорошую концовку
	await enemy.get_tree().create_timer(1.0).timeout
	_show_good_ending()

func _show_good_ending():
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	enemy.get_tree().current_scene.add_child(canvas)

	# Затемнение
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(bg)

	var tw = bg.create_tween()
	tw.tween_property(bg, "color:a", 1.0, 1.5)
	await tw.finished

	bg.color = Color(0, 0, 0, 1)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.custom_minimum_size = Vector2(700, 500)
	vbox.position = Vector2(-350, -250)
	vbox.add_theme_constant_override("separation", 24)
	canvas.add_child(vbox)

	# Заголовок
	var title = Label.new()
	title.text = "ПОБЕДА"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.0))
	title.add_theme_constant_override("outline_size", 3)
	title.add_theme_color_override("font_outline_color", Color(0.5, 0.3, 0.0))
	title.modulate.a = 0.0
	vbox.add_child(title)

	# История
	var story = Label.new()
	story.text = "Вампир повержен!\n\nТы вернул Сердце Священного Дерева в деревню.\nДерево ожило — его листья снова зазеленели,\nа лес наполнился светом и теплом.\n\nСтарейшина встретил тебя с радостью.\nДеревня была спасена.\n\nТвоё имя будут помнить вечно,\nгерой этих земель."
	story.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	story.autowrap_mode = TextServer.AUTOWRAP_WORD
	story.custom_minimum_size = Vector2(650, 0)
	story.add_theme_font_size_override("font_size", 16)
	story.add_theme_color_override("font_color", Color(0.9, 1.0, 0.8))
	story.modulate.a = 0.0
	vbox.add_child(story)

	# Статистика
	var stats = Label.new()
	stats.text = "⭐ Собрано EXP: " + str(GameState.exp) + "\n⚔️ Уровень меча: " + str(GameState.sword_level + 1)
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.add_theme_font_size_override("font_size", 14)
	stats.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	stats.modulate.a = 0.0
	vbox.add_child(stats)

	# Анимация появления
	var tw2 = create_tween()
	tw2.tween_property(title, "modulate:a", 1.0, 1.5)
	tw2.tween_property(story, "modulate:a", 1.0, 2.0)
	tw2.tween_property(stats, "modulate:a", 1.0, 1.0)

	# Кнопка в меню
	await enemy.get_tree().create_timer(5.0).timeout

	var btn = Button.new()
	btn.text = "В главное меню"
	btn.custom_minimum_size = Vector2(220, 50)
	btn.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	btn.position = Vector2(-110, -60)
	btn.add_theme_font_size_override("font_size", 16)
	canvas.add_child(btn)

	btn.modulate.a = 0.0
	var tw3 = btn.create_tween()
	tw3.tween_property(btn, "modulate:a", 1.0, 0.5)

	btn.pressed.connect(func():
		enemy.get_tree().change_scene_to_file("res://menu/menu.tscn")
	)
