extends State

func enter():
	# Отключаем физику и движение
	enemy.set_physics_process(false)
	enemy.velocity = Vector2.ZERO
	enemy.animP.stop()

	# Отключаем коллизии
	enemy.get_node("CollisionShape2D").set_deferred("disabled", true)
	enemy.get_node("Attack_zone").set_deferred("disabled", true)
	enemy.get_node("Attack_area").set_deferred("monitoring", false)

	# Выдаём опыт
	GameState.add_exp(enemy.exp_reward)
	
	# Отмечаем, что босс убит (портал откроется)
	GameState.boss_defeated = true
	print("👑 БОСС ПОБЕЖДЁН! Портал на 3 локацию открыт!")

	# Анимация смерти
	var anim_name = "death_" + enemy.get_direction_string()
	enemy.anim.play(anim_name)
	await enemy.anim.animation_finished

	# Удаляем босса
	enemy.queue_free()
