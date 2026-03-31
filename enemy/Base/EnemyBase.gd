extends CharacterBody2D
class_name EnemyBase

# Характеристики
@export var health: float
@export var damage: float
@export var speed: float

# Данные
@onready var anim = $Movements
@onready var animP = $AnimationPlayer
@onready var state_machine = $StateMachine

enum DIRECTION { DOWN, UP, LEFT, RIGHT }

# Вспомогательные переменные
var idle_dir: DIRECTION = DIRECTION.DOWN
var player: CharacterBody2D
var player_in: bool = false

func _ready() -> void:
	state_machine.init(self)

func _physics_process(_delta: float) -> void:
	state_machine.update()
	move_and_slide()

func take_damage(amount: float):
	if state_machine.current_state.name == "Death":
		return

	health -= amount
	modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	modulate = Color.WHITE

	if health <= 0:
		state_machine.change_state("Death")

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
