extends State

var attacking = false

func enter():
	attacking = true
	attack_loop()

func attack_loop() -> void:
	while attacking and enemy.player_in and enemy.player:
		enemy.velocity = Vector2.ZERO
		enemy.update_attack_direction()
		
		var anim_name_attack = "attack_" + enemy.get_direction_string()
		var anim_name_idle = "idle_" + enemy.get_direction_string()
		enemy.animP.play(anim_name_attack)
		
		await enemy.animP.animation_finished
		enemy.anim.play(anim_name_idle)
		await get_tree().create_timer(enemy.shoot_cooldown).timeout
		
	state_machine.change_state("Chase")

func exit():
	attacking = false
