extends CharacterBody2D

enum DIRECTION { DOWN, UP, LEFT, RIGHT }
enum State{ IDLE, CHASE, ATTACK, DEATH }

@onready var anim = $Movements
@onready var animP = $AnimationPlayer

# Харфктеристики
var heals: float = 15
var damage: float = 5
const SPEED = 70

var idle_dir: DIRECTION = DIRECTION.DOWN
var state: State = State.IDLE
var input_direction = Vector2.ZERO

# Флаги
var player_in: bool = false
var player: CharacterBody2D = null
var can_mov: bool = true
var is_attacking: bool = false

func _physics_process(_delta: float) -> void:
	# Не существуем после смерти
	if state == State.DEATH:
		return

	# Не двигаемся во время атаки
	if !can_mov:
		return

	# Состояния
	match state:
		State.IDLE:
			velocity = Vector2.ZERO
		State.CHASE:
			if player:
				input_direction = (player.position - position).normalized()
				velocity = input_direction * SPEED
		State.ATTACK:
			velocity = Vector2.ZERO

	handle_animation()
	move_and_slide()
	
# Анимация движения
func handle_animation() -> void:
	if player and velocity != Vector2.ZERO:
		if abs(input_direction.x) > abs(input_direction.y):
			if input_direction.x > 0:
				anim.play("Right")
				idle_dir = DIRECTION.RIGHT
			else:
				anim.play("Left")
				idle_dir = DIRECTION.LEFT
		else:
			if input_direction.y > 0:
				anim.play("Down")
				idle_dir = DIRECTION.DOWN
			else:
				anim.play("Up")
				idle_dir = DIRECTION.UP
	else:
		var anim_name = "idle_" + get_direction_string()
		anim.play(anim_name)

# Обновляем направление для удара
func update_attack_direction() -> void:
	if player == null:
		return
	
	var dir = (player.position - position).normalized()
		
	if abs(dir.x) > abs(dir.y):
		if dir.x > 0:
			idle_dir = DIRECTION.RIGHT
		else:
			idle_dir = DIRECTION.LEFT
	else:
		if dir.y > 0:
			idle_dir = DIRECTION.DOWN
		else:
			idle_dir = DIRECTION.UP

# Получение урона
func take_damage(incoming_damage: float) -> void:
	if state == State.DEATH:
		return

	heals -= incoming_damage
	print("enemy: ", heals)
	
	modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	modulate = Color.WHITE

	if heals <= 0:
		call_deferred("die")
		return


# Функция смерти
func die() -> void:
	state = State.DEATH
	can_mov = false

	# Отключаем коллизии
	set_physics_process(false)
	$CollisionShape2D.set_deferred("disabled", true)
	$Attack_zone.set_deferred("disabled", true)
	$Attac_area.set_deferred("monitoring", false)

	var anim_name = "death_" + get_direction_string()
	anim.play(anim_name)
	await anim.animation_finished

	queue_free()

# Выбор анимации по направлению idle
func get_direction_string() -> String:
	match idle_dir:
		DIRECTION.DOWN: return "down"
		DIRECTION.UP: return "up"
		DIRECTION.LEFT: return "left"
		DIRECTION.RIGHT: return "right"

	return "down"

# Анимация атаки
func handle_attack() -> void:
	if is_attacking:
		return

	is_attacking = true
	state = State.ATTACK
	can_mov = false

	while player_in and state != State.DEATH and player != null:
		update_attack_direction()
		
		var anim_name = "attack_" + get_direction_string()
		await get_tree().create_timer(0.1).timeout
		animP.play(anim_name)

		await animP.animation_finished
		await get_tree().create_timer(0.3).timeout

	is_attacking = false
	can_mov = true

# В detector зашел игрок
func _on_ditector_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player = body
		if state != State.ATTACK:
			state = State.CHASE

# Игрок вышел из detector
func _on_ditector_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player = null
		state = State.IDLE

# в attack_zone зашел игрок
func _on_attack_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		state = State.ATTACK
		player_in = true
		if not is_attacking:
			call_deferred("handle_attack")

# Игрок вышел из attack_zone
func _on_attack_zone_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in = false
		state = State.CHASE

# Атака
func _on_attac_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)
