extends State

var saving_damage: float
var duration: float = 4
var timer: float = 0

func enter():
	timer = duration
	saving_damage = enemy.damage
	enemy.damage = enemy.damage_att_1
	enemy.animP.play("special_attack_2")

func update(delta):
	var dir = (enemy.player.position - enemy.position).normalized()
	enemy.velocity = dir * enemy.speed * 1.5
	
	timer -= delta
	
	if timer <= 0:
		timer = duration
		state_machine.change_state("Chase")
	
func exit():
	enemy.damage = saving_damage
