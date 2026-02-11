extends CharacterBody2D

enum DIRECTION { DOWN, UP, LEFT, RIGHT }

@onready var anim = $AnimatedSprite2D

# Константы для скоростей
const WALK_SPEED: float = 100.0
const RUN_SPEED: float = 200.0

var current_speed: float = WALK_SPEED
var idle_dir: DIRECTION = DIRECTION.DOWN
var input_direction := Vector2.ZERO

func _physics_process(_delta: float) -> void:
	# Собираем входные данные
	input_direction = Vector2.ZERO
	# Определяем направление
	input_direction = Input.get_vector("left", "right", "up", "down")
	
	# Нормализуем направление (если двигаемся по диагонали)
	if input_direction.length() > 0:
		input_direction = input_direction.normalized()
	
	# Определяем скорость
	current_speed = RUN_SPEED if Input.is_action_pressed("run") else WALK_SPEED
	
	# Устанавливаем скорость
	velocity = input_direction * current_speed
	
	# Обработка анимаций
	handle_animation()
	
	# Движение
	move_and_slide()

func handle_animation() -> void:
	if input_direction != Vector2.ZERO:
		# Движение
		if abs(input_direction.x) > abs(input_direction.y):
			# Горизонтальное движение
			if input_direction.x > 0:
				anim.play("Front")
				anim.flip_h = true	# Поворачиваем спрайт так как у нас только движение влево
				idle_dir = DIRECTION.RIGHT
			else:
				anim.play("Front")
				anim.flip_h = false
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
		match idle_dir:
			DIRECTION.DOWN:
				anim.play("idle_down")
			DIRECTION.UP:
				anim.play("idle_up")
			DIRECTION.LEFT:
				anim.play("idle_front")
				anim.flip_h = false		# Повораиваем спрайт
			DIRECTION.RIGHT:
				anim.play("idle_front")
				anim.flip_h = true
