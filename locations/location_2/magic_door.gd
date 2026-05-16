extends StaticBody2D

@export var door_cost: int = 100
@export var door_message: String = "Охраняю эту дверь"

var player_nearby: bool = false
var is_open: bool = false
var current_hint: Label = null

@onready var door_sprite = $Sprite2D
@onready var door_collision = $CollisionShape2D
@onready var detection_area = $DetectionArea

func _ready():
	# 👇 УБИРАЕМ ЭТУ СТРОКУ - она меняет цвет спрайта
	# if door_sprite:
	#     door_sprite.modulate = Color(0.5, 0.3, 0.1)
	
	if detection_area:
		detection_area.body_entered.connect(_on_body_entered)
		detection_area.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("player") and not is_open:
		player_nearby = true
		_show_hint(door_message + "\n💰 Нужно " + str(door_cost) + " EXP. Нажми E", Color.YELLOW)

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_nearby = false
		_clear_hint()

func _input(event):
	if event.is_action_pressed("interact") and player_nearby and not is_open:
		_try_open_door()

func _try_open_door():
	if GameState.exp >= door_cost:
		_clear_hint()
		GameState.spend_exp(door_cost)
		_open_door()
	else:
		_show_hint("❌ Не хватает EXP! Нужно " + str(door_cost) + " EXP", Color.RED)
		await get_tree().create_timer(1.5).timeout
		_clear_hint()

func _open_door():
	is_open = true
	
	if door_collision:
		door_collision.disabled = true
	
	var success_msg = Label.new()
	success_msg.text = "✅ Проход открыт! -" + str(door_cost) + " EXP"
	success_msg.add_theme_font_size_override("font_size", 18)
	success_msg.add_theme_color_override("font_color", Color.GREEN)
	success_msg.add_theme_constant_override("outline_size", 2)
	success_msg.add_theme_color_override("font_outline_color", Color.BLACK)
	success_msg.position = global_position + Vector2(-60, -20)
	success_msg.z_index = 100
	get_tree().current_scene.add_child(success_msg)
	
	await get_tree().create_timer(1.5).timeout
	success_msg.queue_free()
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	await tween.finished
	
	queue_free()
	
	print("🚪 Дверь открыта за " + str(door_cost) + " EXP")

func _show_hint(msg: String, color: Color):
	_clear_hint()
	
	current_hint = Label.new()
	current_hint.text = msg
	current_hint.add_theme_font_size_override("font_size", 14)
	current_hint.add_theme_color_override("font_color", color)
	current_hint.add_theme_constant_override("outline_size", 2)
	current_hint.add_theme_color_override("font_outline_color", Color.BLACK)
	current_hint.position = global_position + Vector2(-80, -15)
	current_hint.z_index = 100
	get_tree().current_scene.add_child(current_hint)

func _clear_hint():
	if current_hint:
		current_hint.queue_free()
		current_hint = null
