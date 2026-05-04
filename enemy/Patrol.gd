extends State

var _target: Vector2
var _wait_timer: float = 0.0
var _waiting: bool = true

func enter() -> void:
	_waiting = true
	_wait_timer = randf_range(1.0, 2.5)

func update(delta: float) -> void:
	# Проверяем игрока через player а не player_in
	if enemy.player != null:
		state_machine.change_state("Chase")
		return

	if _waiting:
		_wait_timer -= delta
		if _wait_timer <= 0.0:
			_waiting = false
			_pick_new_target()
		else:
			enemy.anim.play("idle_" + enemy.get_direction_string())
			enemy.velocity = Vector2.ZERO
		return

	var dir = (_target - enemy.global_position)
	if dir.length() < 8.0:
		enemy.velocity = Vector2.ZERO
		_waiting = true
		_wait_timer = randf_range(1.5, 3.0)
		enemy.anim.play("idle_" + enemy.get_direction_string())
		return

	var dir_norm = dir.normalized()
	enemy.velocity = dir_norm * enemy.speed * 0.6

	if abs(dir_norm.x) > abs(dir_norm.y):
		enemy.idle_dir = EnemyBase.DIRECTION.RIGHT if dir_norm.x > 0 else EnemyBase.DIRECTION.LEFT
	else:
		enemy.idle_dir = EnemyBase.DIRECTION.DOWN if dir_norm.y > 0 else EnemyBase.DIRECTION.UP

	var walk_anim = enemy.get_direction_string()
	var idle_anim = "idle_" + enemy.get_direction_string()
	
	# Используем те же анимации что и Chase
	if enemy.anim.sprite_frames.has_animation(walk_anim):
		enemy.anim.play(walk_anim)
	else:
		enemy.anim.play(idle_anim)

func _pick_new_target() -> void:
	var radius = enemy.patrol_radius
	var angle  = randf() * TAU
	_target = enemy.spawn_position + Vector2(cos(angle), sin(angle)) * randf_range(0, radius)
