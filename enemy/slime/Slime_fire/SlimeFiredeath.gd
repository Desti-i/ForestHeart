extends State
@export var fire_sword_drop_chance: float = 0.7
@export var dark_sword_drop_chance: float = 0.99  # ← добавь

func enter():
	enemy.set_physics_process(false)
	enemy.velocity = Vector2.ZERO
	enemy.get_node("CollisionShape2D").set_deferred("disabled", true)
	enemy.get_node("Attack_zone").set_deferred("disabled", true)
	enemy.get_node("Attack_area").set_deferred("monitoring", false)
	GameState.add_exp(enemy.exp_reward)

	var random_value = randf()
	print("⚔️ Шанс выпадения огненного меча: ", fire_sword_drop_chance, " | Выпало: ", random_value)

	if not GameState.fire_sword_unlocked and random_value <= fire_sword_drop_chance:
		GameState.unlock_fire_sword()
		print("⚔️ ОГНЕННЫЙ МЕЧ ВЫПАЛ!")
	else:
		print("⚔️ Огненный меч НЕ выпал")

	# ← добавь этот блок
	var dark_value = randf()
	if not GameState.sword_lvl3_dropped and dark_value <= dark_sword_drop_chance:
		GameState.unlock_sword_lvl3()
		print("⚔️ ТЁМНЫЙ КЛИНОК ВЫПАЛ!")

	var anim_name = "death_" + enemy.get_direction_string()
	enemy.animP.stop()
	enemy.anim.play(anim_name)
	var frames = enemy.anim.sprite_frames.get_frame_count(anim_name)
	var fps = enemy.anim.sprite_frames.get_animation_speed(anim_name)
	var duration = frames / fps
	await enemy.get_tree().create_timer(duration).timeout
	if is_instance_valid(enemy):
		enemy.queue_free()
