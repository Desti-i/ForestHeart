extends State

var saving_damage: float

func enter():
	saving_damage = enemy.damage
	enemy.damage = enemy.damage_att_1
	
	attack_splash()

func attack_splash():
	enemy.velocity = Vector2.ZERO
	enemy.update_attack_direction()
	
	var anim_attack = "attack_splash_" + enemy.get_direction_string()
	enemy.animP.play(anim_attack)
	
	await enemy.animP.animation_finished
	
	state_machine.change_state("Chase")

func exit():
	enemy.damage = saving_damage
