extends State
class_name Death


func enter():
	enemy.set_physics_process(false)
	enemy.velocity = Vector2.ZERO

	enemy.get_node("CollisionShape2D").set_deferred("disabled", true)
	enemy.get_node("Attack_zone").set_deferred("disabled", true)
	enemy.get_node("Attack_area").set_deferred("monitoring", false)

	GameState.add_exp(enemy.exp_reward)


	var anim_name = "death_" + enemy.get_direction_string()

	enemy.animP.stop()
	enemy.anim.play(anim_name)
	enemy.death_sound.play()

	var frames = enemy.anim.sprite_frames.get_frame_count(anim_name)
	var fps = enemy.anim.sprite_frames.get_animation_speed(anim_name)

	var duration = frames / fps

	await enemy.get_tree().create_timer(duration).timeout

	if is_instance_valid(enemy):
		enemy.queue_free()
