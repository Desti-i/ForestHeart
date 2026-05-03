extends State

var attacking: bool = false

func enter() -> void:
	attacking = true
	attack_loop()

func attack_loop() -> void:
	while attacking and enemy.player_in and is_instance_valid(enemy.player):
		enemy.velocity = Vector2.ZERO
		enemy.update_attack_direction()

		var anim_attack = "attack_" + enemy.get_direction_string()
		var anim_idle   = "idle_"   + enemy.get_direction_string()

		# Проверяем что анимация существует
		if not enemy.animP.has_animation(anim_attack):
			break

		enemy.animP.play(anim_attack)
		await enemy.animP.animation_finished

		# После await - проверяем что всё ещё живы и в правильном стейте
		if not attacking:
			return
		if not is_instance_valid(enemy):
			return
		if state_machine.current_state != self:
			return

		enemy.anim.play(anim_idle)
		await get_tree().create_timer(enemy.shoot_cooldown).timeout

		# Снова проверяем после таймера
		if not attacking:
			return
		if not is_instance_valid(enemy):
			return

	# Выходим из атаки
	if not is_instance_valid(enemy):
		return
	if state_machine.current_state == self:
		state_machine.change_state("Chase")

func exit() -> void:
	attacking = false
