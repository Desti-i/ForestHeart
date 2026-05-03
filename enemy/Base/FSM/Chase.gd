extends State
class_name Chase

func update(_delta):
	if enemy.player == null:
		state_machine.change_state("Idle")
		return
		
	var dir = (enemy.player.position - enemy.position).normalized()
	
	if enemy.use_ranged and enemy.player_in:
		state_machine.change_state("RangedAttack")
		return
	
	if enemy.use_melee and enemy.player_in:
		state_machine.change_state("Attack")
		return
	
	enemy.velocity = dir * enemy.speed
	
	# Анимация бега
	if abs(dir.x) > abs(dir.y):
			if dir.x > 0:
				enemy.anim.play("Right")
				enemy.idle_dir = enemy.DIRECTION.RIGHT
			else:
				enemy.anim.play("Left")
				enemy.idle_dir = enemy.DIRECTION.LEFT
	else:
		if dir.y > 0:
			enemy.anim.play("Down")
			enemy.idle_dir = enemy.DIRECTION.DOWN
		else:
			enemy.anim.play("Up")
			enemy.idle_dir = enemy.DIRECTION.UP
