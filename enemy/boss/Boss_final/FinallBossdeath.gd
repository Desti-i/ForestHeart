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
	
	# Сигнал
	GameState.set_final_boss_defeated(true)

	# Анимация смерти
	var anim_name = "death_" + enemy.get_direction_string()
	if enemy.anim.sprite_frames.has_animation(anim_name):
		enemy.death_sound.play()
		enemy.anim.play(anim_name)
		await enemy.anim.animation_finished
	else:
		await get_tree().create_timer(1.0).timeout

	var tw = enemy.create_tween()
	tw.tween_property(enemy, "modulate:a", 0.0, 1.0)
	await tw.finished
	
	GameState.update_save_data()

	enemy.queue_free()
