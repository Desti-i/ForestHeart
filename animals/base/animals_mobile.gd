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
var is_caught: bool = false

@onready var ray = $RayCast2D
@onready var anim = $AnimatedSprite2D
@onready var detection_area = $DetectionArea  

func _ready():
	randomize()
	change_state()
	collision_mask = 1 | 4  
	
	# Подключаем сигнал обнаружения игрока
	if detection_area:
		detection_area.body_entered.connect(_on_player_entered)

func _physics_process(delta):
	if is_caught:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	if state == "move":
		if ray.is_colliding() and randf() < 0.3:
			avoid_obstacle()
		
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

func _on_player_entered(body: Node2D):
	print("🐱 В зону вошло: ", body.name)
	if body.is_in_group("player") and not is_caught:
		if GameState.quest_cat == GameState.QuestState.ACTIVE:
			_catch_cat()

func _catch_cat():
	is_caught = true
	velocity = Vector2.ZERO
	anim.play("Idle")
	
	# Уведомляем GameState, что кошка найдена
	GameState.find_cat()
	
	_show_catch_message()
	
	# Эффект исчезновения
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	await tween.finished
	queue_free()

func _show_catch_message():
	var lbl := Label.new()
	lbl.text = "🐱 Ты нашёл кошку! Отнеси её старейшине!"
	lbl.add_theme_color_override("font_color", Color(0.2, 1.0, 0.3))
	lbl.add_theme_constant_override("outline_size", 2)
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.position = Vector2(200, 100)
	lbl.z_index = 100
	get_tree().current_scene.add_child(lbl)
	
	var tw = create_tween()
	tw.tween_property(lbl, "modulate:a", 0.0, 2.0)
	tw.tween_callback(lbl.queue_free)

func change_state():
	if is_caught:
		return
	
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

func pick_new_direction():
	target_direction = Vector2(
		randf_range(-1, 1),
		randf_range(-1, 1)
	).normalized()

func avoid_obstacle():
	target_direction = direction.rotated(randf_range(-PI/2, PI/2)).normalized()
