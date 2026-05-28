extends State

var saving_damage: float

func enter():
	enemy.special_attack_1.play()
	saving_damage = enemy.damage
	enemy.damage = enemy.damage_att_1
	
	attack_splash()

func attack_splash():
	enemy.velocity = Vector2.ZERO
	enemy.update_attack_direction()
	
	enemy.animP.play("special_attack_1")
	
	await enemy.animP.animation_finished
	
	state_machine.change_state("Chase")

func exit():
	enemy.damage = saving_damage
