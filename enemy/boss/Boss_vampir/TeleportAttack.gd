extends State

@export var teleport_distance := 25

var cooldown := 5.0
var timer := 0.0

func enter():
	timer = cooldown
	
func update(delta):

	timer -= delta

	if timer <= 0:
		timer = cooldown

		teleport_behind_player()
		
func teleport_behind_player():

	if enemy.player == null:
		return

	var player_dir = enemy.player._facing_vector()

	var behind_dir = -player_dir

	var target_pos = enemy.player.global_position + behind_dir * teleport_distance

	enemy.global_position = target_pos
	
	state_machine.change_state("Attack")
	return
