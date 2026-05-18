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
	var scene_tree    = enemy.get_tree()
	var current_scene = scene_tree.current_scene
	var exp_val       = GameState.exp
	var sword_val     = GameState.sword_level
	var anim_name = "death_" + enemy.get_direction_string()
	if enemy.anim.sprite_frames.has_animation(anim_name):
		enemy.anim.play(anim_name)
		await enemy.anim.animation_finished
	else:
		await scene_tree.create_timer(1.0).timeout
	var tw = enemy.create_tween()
	tw.tween_property(enemy, "modulate:a", 0.0, 1.0)
	await tw.finished
	var ending_node = Node.new()
	ending_node.set_script(load("res://enemy/boss/Boss_vampir/EndingRunner.gd"))
	ending_node.set_meta("scene_tree",    scene_tree)
	ending_node.set_meta("current_scene", current_scene)
	ending_node.set_meta("exp_val",       exp_val)
	ending_node.set_meta("sword_val",     sword_val)
	current_scene.add_child(ending_node)
	enemy.queue_free()
