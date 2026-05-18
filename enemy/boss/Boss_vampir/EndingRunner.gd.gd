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

	# Сохраняем данные ДО анимации
	var scene_tree = enemy.get_tree()
	var current_scene = scene_tree.current_scene
	var spawn_pos = enemy.global_position

	# Анимация смерти
	var anim_name = "death_" + enemy.get_direction_string()
	if enemy.anim.sprite_frames.has_animation(anim_name):
		enemy.anim.play(anim_name)
		await enemy.anim.animation_finished
	else:
		await scene_tree.create_timer(1.0).timeout

	# Затухание
	var tw = enemy.create_tween()
	tw.tween_property(enemy, "modulate:a", 0.0, 1.0)
	await tw.finished

	enemy.queue_free()

	# Спавним вампира с выбором
	var vampire_scene = load("res://enemy/boss/FinalVampir.tscn")
	if vampire_scene:
		var vampire = vampire_scene.instantiate()
		vampire.global_position = spawn_pos + Vector2(80, 0)
		current_scene.add_child(vampire)
		print("🧛 Вампир с выбором появился!")
	else:
		print("❌ FinalVampir.tscn не найден!")
