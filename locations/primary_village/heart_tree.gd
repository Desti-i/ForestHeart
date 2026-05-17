extends StaticBody2D

@onready var tree_sprite = $TreeSprite
@onready var heart = $Heart
@onready var detection_area = $DetectionArea
@onready var collision_shape = $CollisionShape2D

var player_nearby: bool = false
var is_alive: bool = true
var intro_shown: bool = false
var countdown_active: bool = false
var countdown_time: float = 180.0
var player_left: bool = false
var waiting_for_return: bool = false

func _ready():
	print("🌳 HeartTree _ready вызван")
	heart.visible = true
	
	if collision_shape:
		collision_shape.disabled = false
		print("✅ CollisionShape2D включен")
	
	if detection_area:
		print("✅ DetectionArea найден")
		detection_area.body_entered.connect(_on_player_entered)
		detection_area.body_exited.connect(_on_player_exited)
		print("✅ Сигналы подключены")
	else:
		print("❌ DetectionArea НЕ НАЙДЕН!")
	
	if GameState.tree_intro_shown:
		intro_shown = true

func _process(delta):
	if countdown_active:
		countdown_time -= delta
		if countdown_time <= 0:
			countdown_active = false
			waiting_for_return = true
			_call_player_to_tree()

func _on_player_entered(body):
	print("🔍 _on_player_entered вызван! Тело: ", body.name)
	if body.is_in_group("player"):
		print("✅ ЭТО ИГРОК! player_nearby = true")
		player_nearby = true
		
		# Если история не показана - показываем
		if not intro_shown:
			print("📖 Показываем историю")
			_show_tree_intro()
		# Если ждём возвращения после таймера - показываем монстра
		elif waiting_for_return and not GameState.monster_encounter_triggered and not GameState.tree_heart_stolen:
			print("👹 ИГРОК ВЕРНУЛСЯ ПОСЛЕ ТАЙМЕРА! ПОКАЗЫВАЕМ МОНСТРА!")
			_show_monster_scene()

func _on_player_exited(body):
	if body.is_in_group("player"):
		print("🚪 Игрок покинул зону дерева!")
		player_nearby = false
		
		# Если история показана и таймер активен - отмечаем, что игрок ушёл
		if intro_shown and countdown_active and not GameState.monster_encounter_triggered:
			player_left = true
			print("⏰ Игрок ушёл во время таймера")

func _show_tree_intro():
	intro_shown = true
	GameState.tree_intro_shown = true
	
	# 👇 Завершаем квест на осмотр дерева
	if GameState.quest_tree_inspect == GameState.QuestState.ACTIVE:
		GameState.complete_tree_inspect()
		_show_notification("🔥 Магия огня открыта! Загляни в меню Q", Color.ORANGE, "🔥")
	
	_show_story_text(
		"🌳 ДРЕВО ЖИЗНИ 🌳\n\nЭто древнее дерево хранит в себе сердце леса.\nТы чувствуешь, что дерево нуждается в твоей защите...",
		Color.GREEN
	)
	
	await get_tree().create_timer(4.0).timeout

	countdown_active = true

func _call_player_to_tree():
	_show_notification("❗ Кто-то приближается к дереву! ВЕРНИСЬ СЕЙЧАС! ❗", Color.RED, "❗")

func _show_monster_scene():
	if GameState.monster_encounter_triggered:
		return
	
	print("👹 НАЧАЛО СЦЕНЫ С МОНСТРОМ!")
	GameState.monster_encounter_triggered = true
	countdown_active = false
	waiting_for_return = false
	
	_show_story_text(
		"👹 ЗЛОДЕЙ ПОЯВИЛСЯ У ДРЕВА! 👹\n\nТы видишь таинственную фигуру в тёмном плаще.\nОно вырывает сердце из дерева и скрывается в пустоте!\n\nДерево начинает увядать на глазах на деревню наступает мрак...",
		Color.ORANGE
	)
	
	await get_tree().create_timer(5.0).timeout
	
	_spawn_monster_npc()
	
	tree_sprite.modulate = Color(0.3, 0.3, 0.3)
	heart.visible = false
	is_alive = false
	
	GameState.tree_heart_stolen = true
	GameState.vampire_spawned = true
	
	await get_tree().create_timer(2.0).timeout
	
	_show_notification("🧛 На карте появился таинственный странник... Найди его на другом берегу, чтобы узнать правду.", Color.PURPLE, "🧛")
	_activate_vampire()

func _spawn_monster_npc():
	var monster_scene = preload("res://NPC/MonsterNPC.tscn")
	var monster = monster_scene.instantiate()
	
	monster.global_position = global_position + Vector2(-10, 40)
	monster.scale = Vector2(1.1, 1.1)
	monster.z_index = 100
	get_tree().current_scene.add_child(monster)

func _activate_vampire():
	var vampire = get_tree().current_scene.find_child("Vampire", true, false)
	if vampire:
		vampire.visible = true
		if vampire.has_method("activate"):
			vampire.activate()

# ========== КРАСИВЫЕ УВЕДОМЛЕНИЯ (увеличенная ширина) ==========

func _show_notification(msg: String, color: Color, icon: String = ""):
	var canvas = CanvasLayer.new()
	canvas.layer = 200
	get_tree().current_scene.add_child(canvas)
	
	var center = Control.new()
	center.anchor_right = 1.0
	center.anchor_bottom = 1.0
	canvas.add_child(center)
	
	var panel = Panel.new()
	panel.size = Vector2(800, 70)  # Увеличено с 500 до 800
	panel.position = Vector2((get_viewport().size.x - 800) / 2, 80)
	panel.z_index = 200
	center.add_child(panel)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.85)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = color
	style.corner_radius_top_left = 15
	style.corner_radius_top_right = 15
	style.corner_radius_bottom_left = 15
	style.corner_radius_bottom_right = 15
	panel.add_theme_stylebox_override("panel", style)
	
	var hbox = HBoxContainer.new()
	hbox.size = Vector2(780, 60)
	hbox.position = Vector2(10, 5)
	hbox.add_theme_constant_override("separation", 15)
	panel.add_child(hbox)
	
	if icon != "":
		var icon_label = Label.new()
		icon_label.text = icon
		icon_label.add_theme_font_size_override("font_size", 32)
		icon_label.add_theme_color_override("font_color", color)
		hbox.add_child(icon_label)
	
	var label = Label.new()
	label.text = msg
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.add_theme_color_override("font_shadow_color", Color.BLACK)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD  # Добавлен перенос текста
	hbox.add_child(label)
	
	panel.position.y = -100
	var tween = create_tween()
	tween.tween_property(panel, "position:y", 80, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
	await get_tree().create_timer(3.0).timeout
	tween = create_tween()
	tween.tween_property(panel, "modulate:a", 0.0, 0.5)
	await tween.finished
	canvas.queue_free()

func _show_story_text(msg: String, color: Color):
	print("📖 ПОКАЗЫВАЕМ ИСТОРИЮ!")
	
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	get_tree().current_scene.add_child(canvas)
	
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.size = get_viewport().size
	overlay.position = Vector2(0, 0)
	overlay.z_index = 98
	canvas.add_child(overlay)
	
	var frame = Panel.new()
	frame.size = Vector2(700, 280)  # Увеличено с 250 до 280
	frame.position = Vector2((get_viewport().size.x - 700) / 2, (get_viewport().size.y - 280) / 2)
	frame.z_index = 100
	canvas.add_child(frame)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.1, 0.95)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = color
	style.corner_radius_top_left = 20
	style.corner_radius_top_right = 20
	style.corner_radius_bottom_left = 20
	style.corner_radius_bottom_right = 20
	style.shadow_size = 10
	style.shadow_offset = Vector2(3, 3)
	style.shadow_color = Color(0, 0, 0, 0.5)
	frame.add_theme_stylebox_override("panel", style)
	
	var label = Label.new()
	label.text = msg
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", 2)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.size = Vector2(640, 230)
	label.position = Vector2(30, 25)
	frame.add_child(label)
	
	frame.scale = Vector2(0.8, 0.8)
	frame.modulate.a = 0
	var tween = create_tween()
	tween.tween_property(frame, "scale", Vector2(1, 1), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(frame, "modulate:a", 1.0, 0.2)
	
	await get_tree().create_timer(5.0).timeout
	
	tween = create_tween()
	tween.tween_property(frame, "scale", Vector2(0.9, 0.9), 0.2)
	tween.parallel().tween_property(frame, "modulate:a", 0.0, 0.3)
	tween.parallel().tween_property(overlay, "modulate:a", 0.0, 0.3)
	await tween.finished
	canvas.queue_free()
