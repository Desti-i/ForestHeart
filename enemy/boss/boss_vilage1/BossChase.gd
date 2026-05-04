extends Chase

var cooldown: float = 5
var timer: float = cooldown

func update(delta):
	super(delta)
	if enemy.phase == 2 and timer <= 0:
		timer = cooldown
		state_machine.change_state("Special_attack_2")
		return
	
	timer -= delta
	if enemy.player:
		var dist = enemy.global_position.distance_to(enemy.player.global_position)
	
		if dist >= 100 and dist <= 149:
			state_machine.change_state("RangedAttack")
			return
		
	if enemy.player_in:
		state_machine.change_state("AttackSelect")
		return
