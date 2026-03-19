extends CharacterBody2D

enum DIRECTION { DOWN, UP, LEFT, RIGHT }

@onready var anim = $Movements
@onready var animP = $AnimationPlayer

var heals: float = 1000
var damage: float = 5

# Константы для скоростей
const WALK_SPEED: float = 100.0
const RUN_SPEED: float = 200.0

var current_speed: float = WALK_SPEED
var idle_dir: DIRECTION = DIRECTION.DOWN
var input_direction := Vector2.ZERO
var can_move: bool = true # переменная для замирания во время атаки

func _physics_process(_delta: float) -> void:
	if !can_move:
		return

	# Определяем атаку
	if Input.is_action_just_pressed("atack"):
		handle_attack()
		return

	# Определяем направление
	input_direction = Vector2.ZERO
	input_direction = Input.get_vector("left", "right", "up", "down").normalized()

	# Определяем скорость
	current_speed = RUN_SPEED if Input.is_action_pressed("run") else WALK_SPEED
	velocity = input_direction * current_speed

	# Обработка движения
	handle_movements()

	move_and_slide()

# Анимация движения
func handle_movements() -> void:
	if input_direction != Vector2.ZERO:
		# Движение
		if abs(input_direction.x) > abs(input_direction.y):
			# Горизонтальное движение
			if input_direction.x > 0:
				anim.play("Right")
				idle_dir = DIRECTION.RIGHT
			else:
				anim.play("Left")
				idle_dir = DIRECTION.LEFT
		else:
			# Вертикальное движение
			if input_direction.y > 0:
				anim.play("Down")
				idle_dir = DIRECTION.DOWN
			else:
				anim.play("Up")
				idle_dir = DIRECTION.UP
	else:
		# Бездействие
		var anim_name = "idle_" + get_direction_string()
		anim.play(anim_name)

# Анимация атаки
func handle_attack() -> void:
	can_move = false
	velocity = Vector2.ZERO

	var anim_name = "attack_1_" + get_direction_string()
	animP.play(anim_name)
				
	await animP.animation_finished
	can_move = true

# Получение урона
func take_damage(incoming_damage: float):
	heals -= incoming_damage

	print("player: ", heals)

	modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	modulate = Color.WHITE

	if heals <= 0:
		queue_free()
		get_tree().change_scene_to_file("res://menu/menu.tscn")

# Выбор анимации по направлению idle
func get_direction_string() -> String:
	match idle_dir:
		DIRECTION.DOWN: return "down"
		DIRECTION.UP: return "up"
		DIRECTION.LEFT: return "left"
		DIRECTION.RIGHT: return "right"

	return "down"

# Атака
func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
