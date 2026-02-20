extends CharacterBody2D

enum DIRECTION { DOWN, UP, LEFT, RIGHT }

@onready var anim = $Movements
@onready var anim_Atack = $Atack

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
		handle_atack()
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

func handle_movements() -> void:
	if input_direction != Vector2.ZERO:
		# Движение
		if abs(input_direction.x) > abs(input_direction.y):
			# Горизонтальное движение
			if input_direction.x > 0:
				anim.flip_h = true	# Поворачиваем спрайт так как у нас только движение влево
				anim.play("Front")
				idle_dir = DIRECTION.RIGHT
			else:
				anim.flip_h = false
				anim.play("Front")
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
			DIRECTION.RIGHT:
				anim.play("idle_front")

func handle_atack() -> void:
	can_move = false
	velocity = Vector2.ZERO
	
	match idle_dir:
			DIRECTION.DOWN:
				anim_Atack.play("atak_1_down")
			DIRECTION.UP:
				anim_Atack.play("atak_1_up")
			DIRECTION.LEFT:
				anim_Atack.play("atak_1_left")
			DIRECTION.RIGHT:
				anim_Atack.play("atak_1_right")
				
	await anim_Atack.animation_finished
	can_move = true
