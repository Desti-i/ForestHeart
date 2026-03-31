extends State

var attacking = false

func enter():
	attacking = true
	attack_loop()

func attack_loop() -> void:
	while attacking and enemy.player_in and enemy.player:
		enemy.velocity = Vector2.ZERO
		enemy.update_attack_direction()
		
		var anim_name = "attack_" + owner.get_direction_string()
		
		owner.animP.play(anim_name)
		
		await owner.animP.animation_finished
		await get_tree().create_timer(0.3).timeout
		
	state_machine.change_state("Chase")

func exit():
	attacking = false
