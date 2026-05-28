extends State

@export var sword_scene: PackedScene
@export var sword_count := 8

var attack_finished := false


func enter():
	enemy.special_attack_2.play()

	attack_finished = false

	enemy.velocity = Vector2.ZERO

	# Анимация атаки
	enemy.animP.play("Special_attack_2")

	# Выпускаем мечи
	spawn_swords()


func update(_delta):

	# Когда анимация закончилась
	if not enemy.animP.is_playing() and not attack_finished:

		attack_finished = true

		# Возвращаем idle
		enemy.anim.play("idle_" + enemy.get_direction_string())

		# Возвращаемся в chase
		state_machine.change_state("Chase")


func spawn_swords():

	for i in sword_count:

		var angle = TAU * i / sword_count

		var dir = Vector2.RIGHT.rotated(angle)

		spawn_sword(dir)


func spawn_sword(dir: Vector2):

	var sword = sword_scene.instantiate()

	sword.global_position = enemy.global_position

	sword.direction = dir

	enemy.get_tree().current_scene.add_child(sword)

func exit():

	enemy.velocity = Vector2.ZERO
