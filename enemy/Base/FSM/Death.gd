extends State

func enter():
	enemy.set_physics_process(false)
	enemy.velocity = Vector2.ZERO

	enemy.animP.stop()

	enemy.get_node("CollisionShape2D").set_deferred("disabled", true)
	enemy.get_node("Attack_zone").set_deferred("disabled", true)
	enemy.get_node("Attack_area").set_deferred("monitoring", false)

	var anim_name = "death_" + enemy.get_direction_string()
	enemy.anim.play(anim_name)
	await enemy.anim.animation_finished

	enemy.queue_free()
