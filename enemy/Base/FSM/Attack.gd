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

		enemy.attack_sound.play()
		enemy.animP.play(anim_attack)
		await enemy.animP.animation_finished

		enemy.anim.play(anim_idle)
		await get_tree().create_timer(enemy.shoot_cooldown).timeout

	if state_machine.current_state == self:
		state_machine.change_state("Chase")

func exit() -> void:
	attacking = false
	enemy.attack_sound.stop()
