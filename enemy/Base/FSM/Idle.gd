extends State

func enter():
	enemy.velocity = Vector2.ZERO
	var anim_name = "idle_" + enemy.get_direction_string()
	enemy.anim.play(anim_name)

func update():
	state_machine.change_state("Chase")
