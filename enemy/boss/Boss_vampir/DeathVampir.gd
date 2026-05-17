extends State

func enter():
	enemy.set_physics_process(false)
	enemy.velocity = Vector2.ZERO
	enemy.animP.stop()

	enemy.get_node("CollisionShape2D").set_deferred("disabled", true)
	enemy.get_node("Attack_zone").set_deferred("disabled", true)
	enemy.get_node("Attack_area").set_deferred("monitoring", false)

	GameState.add_exp(enemy.exp_reward)
	
	# 🩸 Выпадение магии крови с босса
	if not GameState.blood_magic_unlocked:
		GameState.unlock_blood_magic()
		print("🩸 МАГИЯ КРОВИ ВЫПАЛА С БОССА!")
	
	# Отмечаем, что босс убит (портал откроется)
	GameState.boss_defeated = true
	print("👑 БОСС ПОБЕЖДЁН! Портал на 3 локацию открыт!")

	var anim_name = "death_" + enemy.get_direction_string()
	enemy.anim.play(anim_name)
	await enemy.anim.animation_finished

	enemy.queue_free()
