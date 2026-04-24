extends CharacterBody2D

@export var speed: float = 40.0
@export var turn_speed: float = 3.0

@export var move_time_min: float = 2.0
@export var move_time_max: float = 4.0
@export var idle_time_min: float = 2.0
@export var idle_time_max: float = 3.0

var direction: Vector2 = Vector2.RIGHT
var target_direction: Vector2 = Vector2.RIGHT
var state: String = "idle"

@onready var ray = $RayCast2D
@onready var anim = $AnimatedSprite2D

func _ready():
	randomize()
	change_state()


func _physics_process(delta):
	if state == "move":
		# избегание стен
		if ray.is_colliding() and randf() < 0.3:
			avoid_obstacle()

		# плавный поворот
		direction = direction.lerp(target_direction, turn_speed * delta)

		if abs(direction.x) > abs(direction.y):
			if direction.x > 0:
				anim.play("Right")
			else:
				anim.play("Left")
		else:
			if direction.y > 0:
				anim.play("Down")
			else:
				anim.play("Up")

		velocity = direction * speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()

	ray.target_position = direction * 15




# --- СОСТОЯНИЯ ---

func change_state():
	if state == "idle":
		start_move()
	else:
		start_idle()


func start_move():
	state = "move"
	pick_new_direction()

	var time = randf_range(move_time_min, move_time_max)
	await get_tree().create_timer(time).timeout
	change_state()


func start_idle():
	state = "idle"

	var time = randf_range(idle_time_min, idle_time_max)
	anim.play("Idle")
	await get_tree().create_timer(time).timeout
	change_state()


# --- ПОВЕДЕНИЕ ---

func pick_new_direction():
	target_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()


func avoid_obstacle():
	target_direction = direction.rotated(randf_range(-PI/2, PI/2)).normalized()
