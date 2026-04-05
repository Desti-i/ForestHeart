extends CharacterBody2D

signal health_changed(new_health, max_health)

enum DIRECTION { DOWN, UP, LEFT, RIGHT }

@onready var anim = $Movements
@onready var animP = $AnimationPlayer
@onready var hp_bar = $"../CanvasLayer/Control/hp_bar"

var max_health: float = 100
var current_health: float = 100
var damage: float = 5

const WALK_SPEED: float = 100.0
const RUN_SPEED: float = 200.0

var current_speed: float = WALK_SPEED
var idle_dir: DIRECTION = DIRECTION.DOWN
var input_direction := Vector2.ZERO
var can_move: bool = true
var is_invincible: bool = false

# --- РЕГЕН ---
var regen_delay: float = 3.0
var regen_amount: float = 20
var regen_timer: float = 0.0

func _ready():
	current_health = max_health
	
	if hp_bar:
		hp_bar.max_value = max_health
		hp_bar.min_value = 0
		hp_bar.value = current_health

func _physics_process(delta: float) -> void:
	if !can_move:
		return

	# Атака
	if Input.is_action_just_pressed("atack"):
		handle_attack()
		return

	# Движение
	input_direction = Input.get_vector("left", "right", "up", "down").normalized()
	current_speed = RUN_SPEED if Input.is_action_pressed("run") else WALK_SPEED
	velocity = input_direction * current_speed

	handle_movements()
	move_and_slide()

	# --- РЕГЕН ---
	if current_health > 0 and current_health < max_health:
		regen_timer += delta
		
		if regen_timer >= regen_delay:
			heal(regen_amount)
			regen_timer = 0.0  # сбрасываем, чтобы лечило каждые 3 сек

func handle_movements() -> void:
	if input_direction != Vector2.ZERO:
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

func handle_attack() -> void:
	can_move = false
	velocity = Vector2.ZERO
	var anim_name = "attack_1_" + get_direction_string()
	animP.play(anim_name)
	await animP.animation_finished
	can_move = true

func take_damage(incoming_damage: float) -> void:
	if is_invincible:
		return
	
	current_health -= incoming_damage
	current_health = max(current_health, 0)
	
	# ❗ СБРОС ТАЙМЕРА РЕГЕНА
	regen_timer = 0.0
	
	if hp_bar:
		hp_bar.value = current_health
	
	health_changed.emit(current_health, max_health)
	
	modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	modulate = Color.WHITE
	
	if current_health <= 0:
		die()

func heal(amount: float) -> void:
	current_health += amount
	current_health = min(current_health, max_health)
	
	if hp_bar:
		hp_bar.value = current_health
	
	health_changed.emit(current_health, max_health)
	
	if animP.has_animation("heal"):
		animP.play("heal")


func die() -> void:
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://menu/menu.tscn")

func get_direction_string() -> String:
	match idle_dir:
		DIRECTION.DOWN: return "down"
		DIRECTION.UP: return "up"
		DIRECTION.LEFT: return "left"
		DIRECTION.RIGHT: return "right"
	return "down"

func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
