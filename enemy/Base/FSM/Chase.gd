extends State
class_name Chase

func enter():
	enemy.chase_sound.play()
	
func exit():
	enemy.chase_sound.stop()

func update(_delta):
	if enemy.player == null:
		# Возвращаемся к патрулю если есть
		if state_machine.has_node("Patrol"):
			state_machine.change_state("Patrol")
		else:
			state_machine.change_state("Idle")
		return

	if enemy.use_ranged and enemy.player_in:
		state_machine.change_state("RangedAttack")
		return

	if enemy.use_melee and enemy.player_in:
		state_machine.change_state("Attack")
		return

	var dir = (enemy.player.position - enemy.position).normalized()
	enemy.velocity = dir * enemy.speed

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
