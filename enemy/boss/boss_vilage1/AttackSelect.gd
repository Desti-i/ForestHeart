extends State

var diff_attack: bool = true

func enter():
	var r = randf()
	
	if enemy.phase == 1:
		select_Attack(r, 0.3)
	else:
		select_Attack(r, 0.5)

func select_Attack(r: float, oddc: float):
	if r < oddc and diff_attack:
		diff_attack = false
		state_machine.change_state("Special_attack_1")
	else:
		diff_attack = true
		state_machine.change_state("Attack")
