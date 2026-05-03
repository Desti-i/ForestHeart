extends CharacterBody2D
class_name EnemyBase

var health: float
@export var max_health: float = 50.0
@export var damage: float = 10.0
@export var speed: float = 60.0
@export var exp_reward: int = 20
@export var use_melee: bool = true
@export var use_ranged: bool = false
@export var speed_ammo: float = 20
@export var shoot_cooldown: float = 1.2
@export var bullet_scene: PackedScene

@onready var anim         = $Movements
@onready var animP        = $AnimationPlayer
@onready var state_machine = $StateMachine
@onready var hp_bar       = $TextureProgressBar

enum DIRECTION { DOWN, UP, LEFT, RIGHT }

var idle_dir:  DIRECTION = DIRECTION.DOWN
var player:    CharacterBody2D
var player_in: bool = false

func _ready() -> void:
	health = max_health
	if hp_bar:
		hp_bar.max_value = max_health
		hp_bar.min_value = 0
		hp_bar.value     = health
		hp_bar.visible   = false  # Скрыт пока не получит урон
	state_machine.init(self)

func _physics_process(delta: float) -> void:
	state_machine.update(delta)
	move_and_slide()
	if hp_bar:
		hp_bar.global_position = global_position + Vector2(-20, -45)

func take_damage(amount: float) -> void:
	if state_machine.current_state.name == "Death":
		return

	health -= amount
	health  = max(health, 0)

	if hp_bar:
		hp_bar.value   = health
		hp_bar.visible = true  # Показываем при получении урона

	# Всплывающий урон
	_show_damage_number(amount)

	# Красная вспышка
	modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	modulate = Color.WHITE

	if health <= 0:
		if hp_bar:
			hp_bar.visible = false
		state_machine.change_state("Death")

func _show_damage_number(amount: float) -> void:
	var lbl := Label.new()

	# Цвет зависит от величины урона
	var color: Color
	if amount >= 40:
		color = Color(1.0, 0.0, 0.0)    # красный - критический
		lbl.text = "💥 " + str(int(amount))
	elif amount >= 20:
		color = Color(1.0, 0.5, 0.0)    # оранжевый - средний
		lbl.text = str(int(amount))
	else:
		color = Color(1.0, 1.0, 0.2)    # жёлтый - малый
		lbl.text = str(int(amount))

	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_constant_override("outline_size", 2)
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)

	# Случайный сдвиг по X чтобы числа не сливались
	var offset_x = randf_range(-12, 12)
	lbl.global_position = global_position + Vector2(offset_x, -30)
	lbl.z_index = 100

	get_tree().current_scene.add_child(lbl)

	# Анимация - летит вверх и исчезает
	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl, "global_position:y", lbl.global_position.y - 35, 0.8)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.8)
	tw.tween_property(lbl, "scale", Vector2(1.3, 1.3), 0.15)
	tw.chain().tween_callback(lbl.queue_free)

func update_attack_direction() -> void:
	if player == null:
		return
	var dir = (player.position - position).normalized()
	if abs(dir.x) > abs(dir.y):
		idle_dir = DIRECTION.RIGHT if dir.x > 0 else DIRECTION.LEFT
	else:
		idle_dir = DIRECTION.DOWN if dir.y > 0 else DIRECTION.UP

func get_direction_string() -> String:
	match idle_dir:
		DIRECTION.DOWN:  return "down"
		DIRECTION.UP:    return "up"
		DIRECTION.LEFT:  return "left"
		DIRECTION.RIGHT: return "right"
	return "down"

func _on_detector_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player = body
		state_machine.change_state("Chase")

func _on_detector_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player = null
		state_machine.change_state("Idle")

func _on_attack_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in = true

func _on_attack_zone_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in = false

func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)
