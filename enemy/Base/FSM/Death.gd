extends State

@export var water_magic_drop_chance: float = 1.0 / 15.0  # Шанс 1 к 15 (6.67%)

func enter():
	# Отключаем физику
	enemy.set_physics_process(false)
	enemy.velocity = Vector2.ZERO
	enemy.animP.stop()

	# Отключаем коллизии
	enemy.get_node("CollisionShape2D").set_deferred("disabled", true)
	enemy.get_node("Attack_zone").set_deferred("disabled", true)
	enemy.get_node("Attack_area").set_deferred("monitoring", false)

	# ── Выдаём опыт игроку ──
	GameState.add_exp(enemy.exp_reward)
	
	# ── Шанс выпадения магии воды ──
	var random_value = randf()
	print("💧 Шанс дропа: ", water_magic_drop_chance, " | Выпало: ", random_value)
	
	if not GameState.water_magic_unlocked and random_value <= water_magic_drop_chance:
		GameState.unlock_water_magic()
		print("💧 💧 💧 МАГИЯ ВОДЫ ВЫПАЛА! 💧 💧 💧")
	else:
		print("💧 Магия воды НЕ выпала в этот раз")
	
	# Анимация смерти
	var anim_name = "death_" + enemy.get_direction_string()
	enemy.anim.play(anim_name)
	await enemy.anim.animation_finished

	# Удаляем моба
	enemy.queue_free()
