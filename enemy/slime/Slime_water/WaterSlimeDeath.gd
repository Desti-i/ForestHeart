extends State

@export var water_magic_drop_chance: float = 0.05

func enter():
	enemy.set_physics_process(false)
	enemy.velocity = Vector2.ZERO

	enemy.get_node("CollisionShape2D").set_deferred("disabled", true)
	enemy.get_node("Attack_zone").set_deferred("disabled", true)
	enemy.get_node("Attack_area").set_deferred("monitoring", false)

	# Выдаём опыт
	GameState.add_exp(enemy.exp_reward)

	var random_value = randf()
	print("💧 Шанс выпадения магии воды: ", water_magic_drop_chance, " | Выпало: ", random_value)
	
	if not GameState.water_magic_unlocked and random_value <= water_magic_drop_chance:
		GameState.unlock_water_magic()
		print("💧 МАГИЯ ВОДЫ ВЫПАЛА С ВОДНОЙ СЛИЗИ!")
	else:
		print("💧 Магия воды НЕ выпала в этот раз")

	# Анимация смерти
	var anim_name = "death_" + enemy.get_direction_string()
	enemy.animP.stop()
	enemy.anim.play(anim_name)

	var frames = enemy.anim.sprite_frames.get_frame_count(anim_name)
	var fps = enemy.anim.sprite_frames.get_animation_speed(anim_name)
	var duration = frames / fps

	await enemy.get_tree().create_timer(duration).timeout

	if is_instance_valid(enemy):
		enemy.queue_free()
