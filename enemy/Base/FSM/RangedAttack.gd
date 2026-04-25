extends State

var attack_id: float = 0
var cooldown: float = 0

func enter():
	cooldown = 0

func update(delta):
	if enemy.player_in == false:
		
		state_machine.change_state("Chase")
		return
	
	enemy.velocity = Vector2.ZERO
	enemy.update_attack_direction()
	
	cooldown -=delta
	
	if cooldown <= 0:
		attack_id += 1
		shoot_once(attack_id)
		cooldown = enemy.shoot_cooldown
		
func shoot_once(id):
	var dir = (enemy.player.position - enemy.position).normalized()
		
	var anim_name_attack = "attack_" + enemy.get_direction_string()
	var anim_name_idle = "idle_" + enemy.get_direction_string()		
	enemy.anim.play(anim_name_attack)
		
	await enemy.anim.animation_finished
	enemy.anim.play(anim_name_idle)
			
	if id != attack_id:
		return 
	
	var target_pos = enemy.player.global_position
	shoot(dir, target_pos)
	
func shoot(dir: Vector2, target_pos: Vector2):
	if enemy.bullet_scene == null:
		return
	
	var bullet = enemy.bullet_scene.instantiate()
	bullet.global_position = enemy.global_position + dir * 10
	bullet.direction = dir
	bullet.damage = enemy.damage
	bullet.speed = enemy.speed_ammo
	bullet.target_position = target_pos
	
	enemy.get_tree().current_scene.add_child(bullet)
