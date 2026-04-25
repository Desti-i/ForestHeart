extends CharacterBody2D
class_name EnemyBase

# Характеристики
@export var health: float = 50.0
@export var max_health: float = 50.0
@export var damage: float = 10.0
@export var speed: float = 60.0

@export var use_melee: bool = true
@export var use_ranged: bool = false

@export var speed_ammo: float = 20
#@export var renged_range: float = 0
@export var shoot_cooldown: float = 1.2
@export var bullet_scene: PackedScene

# Данные
@onready var anim = $Movements
@onready var animP = $AnimationPlayer
@onready var state_machine = $StateMachine
@onready var hp_bar = $TextureProgressBar

enum DIRECTION { DOWN, UP, LEFT, RIGHT }

# Вспомогательные переменные
var idle_dir: DIRECTION = DIRECTION.DOWN
var player: CharacterBody2D
var player_in: bool = false

func _ready() -> void:
	# Инициализируем здоровье
	health = max_health
	
	# Настраиваем HP бар
	if hp_bar:
		hp_bar.max_value = max_health
		hp_bar.min_value = 0
		hp_bar.value = health
		hp_bar.visible = true  # Показываем полоску
	
	state_machine.init(self)

func _physics_process(delta: float) -> void:
	state_machine.update(delta)
	move_and_slide()
	
	# Обновляем позицию HP бара (чтобы всегда был над головой)
	if hp_bar:
		hp_bar.global_position = global_position + Vector2(0, -40)  # Над головой

func take_damage(amount: float):
	if state_machine.current_state.name == "Death":
		return

	health -= amount
	health = max(health, 0)  # Не уходим в минус
	
	# Обновляем HP бар
	if hp_bar:
		hp_bar.value = health
	
	# Визуальный эффект
	modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	modulate = Color.WHITE
	
	print("Enemy health: ", health, "/", max_health)  # Отладка

	if health <= 0:
		state_machine.change_state("Death")
		
		# Скрываем HP бар при смерти
		if hp_bar:
			hp_bar.visible = false

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

# Выбор анимации по направлению idle
func get_direction_string() -> String:
	match idle_dir:
		DIRECTION.DOWN: return "down"
		DIRECTION.UP: return "up"
		DIRECTION.LEFT: return "left"
		DIRECTION.RIGHT: return "right"
	return "down"

# Сигналы
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
