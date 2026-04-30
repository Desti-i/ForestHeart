extends CharacterBody2D

signal health_changed(new_health, max_health)
signal stamina_changed(cur: float, max_val: float)

enum DIRECTION { DOWN, UP, LEFT, RIGHT }

@onready var anim  = $Movements
@onready var animP = $AnimationPlayer
@onready var hp_bar = $"../CanvasLayer/Control/hp_bar"
@onready var hp_label = $"../CanvasLayer/Control/hp_bar/Label"
@onready var q_menu = $"../CanvasLayer/QMenu"

var max_health:     float = 100
var current_health: float = 100
var damage:         float = 5.0

const WALK_SPEED: float = 100.0
const RUN_SPEED:  float = 200.0

var current_speed: float = WALK_SPEED
var idle_dir:      DIRECTION = DIRECTION.DOWN
var input_direction := Vector2.ZERO
var can_move:      bool = true
var is_invincible: bool = false
var _q_menu_open:  bool = false

var regen_delay:  float = 3.0
var regen_amount: float = 20
var regen_timer:  float = 0.0

@export var max_stamina:       float = 100.0
@export var stamina_regen:     float = 22.0
@export var run_stamina_cost:  float = 16.0
@export var dash_stamina_cost: float = 25.0
var stamina: float

@export var dash_speed:    float = 480.0
@export var dash_duration: float = 0.16
@export var dash_cooldown: float = 0.9

var _dashing:     bool    = false
var _dash_timer:  float   = 0.0
var _dash_cd:     float   = 0.0
var _dash_dir:    Vector2 = Vector2.ZERO

func _ready() -> void:
	current_health = max_health
	stamina        = max_stamina
	if hp_bar:
		hp_bar.max_value = max_health
		hp_bar.min_value = 0
		hp_bar.value     = current_health
	if hp_label:
		print("✅ hp_label найден!")
		hp_label.text = "100/100"
		hp_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	else:
		print("❌ hp_label НЕ найден!")
	_update_hp_label()
	damage = GameState.get_active_weapon()["damage"]
	GameState.weapon_changed.connect(_on_weapon_changed)
	if q_menu:
		q_menu.visible = false

func _on_weapon_changed(weapon: Dictionary) -> void:
	damage = weapon["damage"]
	print("⚔️ Меч улучшен! Цвет:", weapon["color"])

func _physics_process(delta: float) -> void:
	_dash_cd = max(0.0, _dash_cd - delta)

	if _dashing:
		_dash_timer -= delta
		velocity = _dash_dir * dash_speed
		move_and_slide()
		modulate.a = 0.5 if int(_dash_timer * 20) % 2 == 0 else 1.0
		if _dash_timer <= 0.0:
			_dashing = false
			is_invincible = false
			modulate.a = 1.0
			velocity = Vector2.ZERO
		return

	if Input.is_action_just_pressed("open_menu"):
		_toggle_q_menu()
		return

	if _q_menu_open:
		return

	if !can_move:
		return

	if Input.is_action_just_pressed("atack"):
		handle_attack()
		return

	if Input.is_action_just_pressed("dash") and _dash_cd <= 0.0 and stamina >= dash_stamina_cost and stamina > max_stamina * 0.1:
		_start_dash()
		return

	input_direction = Input.get_vector("left", "right", "up", "down").normalized()
	var is_running_key_pressed = Input.is_action_pressed("run") and input_direction != Vector2.ZERO

	if is_running_key_pressed:
		stamina = max(0.0, stamina - run_stamina_cost * delta)
		emit_signal("stamina_changed", stamina, max_stamina)

	if is_running_key_pressed and stamina > max_stamina * 0.1:
		current_speed = RUN_SPEED
	else:
		current_speed = WALK_SPEED

	velocity = input_direction * current_speed

	if not is_running_key_pressed:
		var prev := stamina
		stamina = min(max_stamina, stamina + stamina_regen * delta)
		if stamina != prev:
			emit_signal("stamina_changed", stamina, max_stamina)

	handle_movements()
	move_and_slide()

	if current_health > 0 and current_health < max_health:
		regen_timer += delta
		if regen_timer >= regen_delay:
			heal(regen_amount)
			regen_timer = 0.0

func _toggle_q_menu() -> void:
	if q_menu:
		_q_menu_open = !_q_menu_open
		q_menu.visible = _q_menu_open
		can_move = !_q_menu_open
		if _q_menu_open:
			q_menu.refresh()

func _start_dash() -> void:
	_dash_dir     = input_direction if input_direction != Vector2.ZERO else _facing_vector()
	_dashing      = true
	_dash_timer   = dash_duration
	_dash_cd      = dash_cooldown
	stamina      -= dash_stamina_cost
	is_invincible = true
	emit_signal("stamina_changed", stamina, max_stamina)

func _facing_vector() -> Vector2:
	match idle_dir:
		DIRECTION.DOWN:  return Vector2.DOWN
		DIRECTION.UP:    return Vector2.UP
		DIRECTION.LEFT:  return Vector2.LEFT
		DIRECTION.RIGHT: return Vector2.RIGHT
	return Vector2.DOWN

func handle_movements() -> void:
	if input_direction != Vector2.ZERO:
		if abs(input_direction.x) > abs(input_direction.y):
			if input_direction.x > 0:
				anim.play("Right"); idle_dir = DIRECTION.RIGHT
			else:
				anim.play("Left");  idle_dir = DIRECTION.LEFT
		else:
			if input_direction.y > 0:
				anim.play("Down"); idle_dir = DIRECTION.DOWN
			else:
				anim.play("Up");   idle_dir = DIRECTION.UP
	else:
		anim.play("idle_" + get_direction_string())

func handle_attack() -> void:
	can_move = false
	velocity = Vector2.ZERO
	var weapon = GameState.get_active_weapon()
	# Используем anim_prefix из GameState
	animP.play(weapon["anim_prefix"] + get_direction_string())
	await animP.animation_finished
	can_move = true

func take_damage(incoming_damage: float) -> void:
	if is_invincible:
		return
	current_health -= incoming_damage
	current_health  = max(current_health, 0)
	regen_timer     = 0.0
	if hp_bar:
		hp_bar.value = current_health
	health_changed.emit(current_health, max_health)
	_update_hp_label()
	modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	modulate = Color.WHITE
	if current_health <= 0:
		die()

func heal(amount: float) -> void:
	current_health = min(current_health + amount, max_health)
	if hp_bar:
		hp_bar.value = current_health
	health_changed.emit(current_health, max_health)
	_update_hp_label()

func die() -> void:
	if current_health > 0:
		return
	
	print("💀 Игрок умер!")
	
	# Отключаем движение и ввод
	set_physics_process(false)
	set_process_input(false)
	can_move = false
	velocity = Vector2.ZERO
	
	# Отключаем сигналы
	if GameState and GameState.weapon_changed.is_connected(_on_weapon_changed):
		GameState.weapon_changed.disconnect(_on_weapon_changed)
	
	# Прячем меню
	if q_menu:
		q_menu.visible = false
	
	# Проверяем анимацию смерти в AnimatedSprite2D (Movements)
	if anim and anim.sprite_frames.has_animation("death"):
		print("💀 Найдена анимация смерти в Movements, проигрываем")
		anim.play("death")
		
		# Ждём окончания анимации или просто таймер
		await get_tree().create_timer(3.4).timeout
	else:
		print("💀 Анимации смерти нет, просто ждём")
		await get_tree().create_timer(1.0).timeout
	
	# Смена сцены
	if is_inside_tree():
		get_tree().change_scene_to_file("res://menu/menu.tscn")

func get_direction_string() -> String:
	match idle_dir:
		DIRECTION.DOWN:  return "down"
		DIRECTION.UP:    return "up"
		DIRECTION.LEFT:  return "left"
		DIRECTION.RIGHT: return "right"
	return "down"

func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)

func _update_hp_label() -> void:
	if hp_label:
		hp_label.text = str(int(current_health)) + " / " + str(int(max_health))
		hp_label.remove_theme_color_override("font_color")
		hp_label.remove_theme_color_override("font_outline_color")
		hp_label.remove_theme_constant_override("outline_size")
		hp_label.add_theme_constant_override("outline_size", 2)
		hp_label.add_theme_color_override("font_outline_color", Color.BLACK)
		var health_percent = current_health / max_health
		if health_percent <= 0.2:
			hp_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
		elif health_percent <= 0.5:
			hp_label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.2))
		else:
			hp_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
		hp_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
		hp_label.add_theme_constant_override("shadow_offset_x", 1)
		hp_label.add_theme_constant_override("shadow_offset_y", 1)
		hp_label.scale = Vector2(1.1, 1.1)
		await get_tree().create_timer(0.1).timeout
		hp_label.scale = Vector2(1.0, 1.0)
