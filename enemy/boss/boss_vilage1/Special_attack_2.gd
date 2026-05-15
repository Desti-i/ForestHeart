extends State

var saving_damage: float

var duration := 4.0
var timer := 0.0

var damage_tick := 0.5
var damage_timer := 0.0


func enter():
	timer = duration
	damage_timer = 0
	
	saving_damage = enemy.damage
	enemy.damage = enemy.damage_att_1
	
	enemy.animP.play("special_attack_2")


func update(delta):
	if enemy.player == null:
		state_machine.change_state("Chase")
		return
	
	var dir = (enemy.player.position - enemy.position).normalized()
	enemy.velocity = dir * enemy.speed * 1.5
	
	timer -= delta
	damage_timer -= delta
	
	if damage_timer <= 0:
		damage_timer = damage_tick
		
		if enemy.player_in:
			enemy.player.take_damage(enemy.damage)
	
	if timer <= 0:
		state_machine.change_state("Chase")


func exit():
	enemy.damage = saving_damage
	enemy.velocity = Vector2.ZERO
