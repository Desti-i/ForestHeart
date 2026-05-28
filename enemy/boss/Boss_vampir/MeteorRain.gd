extends State

@export var meteor_scene: PackedScene

var duration := 15
var timer := 0.0

var spawn_interval := 0.25
var spawn_timer := 0.0

func enter():
	
	timer = duration
	spawn_timer = 0.0

	enemy.velocity = Vector2.ZERO
	enemy.special_attack_2.play()

	enemy.anim.play("meteor_cast")

func update(delta):

	timer -= delta
	spawn_timer -= delta

	if spawn_timer <= 0:
		spawn_timer = spawn_interval
		spawn_meteor()

	if timer <= 0:
		state_machine.change_state("Chase")
		
func spawn_meteor():

	var room_top_left = enemy.get_parent().get_node("RoomTopLeft")
	var room_bottom_right = enemy.get_parent().get_node("RoomBottomRight")
	
	var random_x = randf_range(
	room_top_left.global_position.x,
	room_bottom_right.global_position.x
)

	var random_y = randf_range(
		room_top_left.global_position.y,
		room_bottom_right.global_position.y
	)

	var pos = Vector2(random_x, random_y)

	var meteor = meteor_scene.instantiate()

	meteor.global_position = pos

	enemy.get_tree().current_scene.add_child(meteor)
