extends Area2D

@onready var tree_sprite = $TreeSprite
@onready var heart = $Heart
@onready var detection_area = $DetectionArea

var player_nearby: bool = false
var is_alive: bool = true



func _ready():
	heart.visible = true
	
	if detection_area:
		detection_area.body_entered.connect(_on_player_entered)
		detection_area.body_exited.connect(_on_player_exited)

func _process(delta):
	if player_nearby and Input.is_action_just_pressed("interact") and is_alive:
		_steal_heart()

func _on_player_entered(body):
	if body.is_in_group("player") and is_alive:
		player_nearby = true
		_show_hint("🌳 Нажми E, чтобы подойти к дереву")

func _on_player_exited(body):
	if body.is_in_group("player"):
		player_nearby = false

func _steal_heart():
	print("🌳 Сердце дерева украдено!")
	is_alive = false
	player_nearby = false
	
	# Меняем цвет дерева на серый (засохшее)
	var tween = create_tween()
	tween.tween_property(tree_sprite, "modulate", Color(0.5, 0.4, 0.3), 0.5)
	
	# Сердце исчезает
	tween.tween_property(heart, "modulate:a", 0.0, 0.3)
	await tween.finished
	heart.visible = false
	
	_show_effect("💔 Сердце дерева украдено! Появился вампир... 💔", Color.RED)
	
	GameState.tree_heart_stolen = true
	GameState.vampire_spawned = true
	
	_spawn_vampire()

func _spawn_vampire():
	var vampire = get_tree().current_scene.find_child("vampire", true, false)
	if not vampire:
		vampire = get_tree().current_scene.find_child("Vampire", true, false)
	
	if vampire:
		vampire.visible = true
		if vampire.has_method("activate"):
			vampire.activate()
		print("🧛 Вампир активирован!")
	else:
		print("⚠️ Вампир не найден!")

func restore():
	is_alive = false
	var tween = create_tween()
	tween.tween_property(tree_sprite, "modulate", Color(1, 1, 1), 0.5)
	heart.visible = true
	heart.modulate.a = 1.0
	_show_effect("🌳 Дерево жизни ожило! Спасибо, герой! 🌳", Color.GREEN)

func _show_hint(msg: String):
	var lbl = Label.new()
	lbl.text = msg
	lbl.add_theme_color_override("font_color", Color.YELLOW)
	lbl.add_theme_constant_override("outline_size", 1)
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.position = global_position + Vector2(-80, -70)
	lbl.z_index = 100
	get_parent().add_child(lbl)
	var tween = create_tween()
	tween.tween_property(lbl, "modulate:a", 0.0, 2.0)
	tween.tween_callback(lbl.queue_free)

func _show_effect(msg: String, color: Color):
	var lbl = Label.new()
	lbl.text = msg
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_constant_override("outline_size", 2)
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.position = Vector2(200, 150)
	lbl.z_index = 200
	get_tree().current_scene.add_child(lbl)
	var tween = create_tween()
	tween.tween_property(lbl, "modulate:a", 0.0, 3.0)
	tween.tween_callback(lbl.queue_free)
	
	
