extends Chase

var timer: float
var cooldown: float = 10

func enter():
	timer = cooldown

func update(delta):
	super(delta)
	
	if enemy.phase == 2 and timer <= 0:
		timer = cooldown
		state_machine.change_state("Special_atack_2")
	
	timer -= delta
	
	if enemy.global_position.distant_to(enemy.player.global_position) >= enemy.range_shot:
		state_machine.change_state("RangedAttack")
		
	if enemy.player_in:
		state_machine.change_state("AttackSelect")
