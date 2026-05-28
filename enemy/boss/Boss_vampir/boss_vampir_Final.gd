extends CharacterBody2D

@export var npc_name: String = "Вампир"

@onready var animated_sprite = $AnimatedSprite2D

var player_nearby: bool = false
var dialog_open: bool = false
var showing_choice: bool = false

var canvas_layer: CanvasLayer
var dialog_panel: PanelContainer
var name_label: Label
var dialog_label: Label
var choice_container: HBoxContainer
var choice_btn_1: Button
var choice_btn_2: Button

func _ready():
	_create_ui()
	if animated_sprite:
		animated_sprite.play("idle")
	
	var area = $DetectionArea
	if area:
		area.body_entered.connect(_on_body_entered)
		area.body_exited.connect(_on_body_exited)
	
	# Появляемся с анимацией
	modulate.a = 0.0
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 1.0)
	

func _create_ui():
	canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 10
	add_child(canvas_layer)

	dialog_panel = PanelContainer.new()
	dialog_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	dialog_panel.offset_top  = -240
	dialog_panel.offset_left = 80
	dialog_panel.offset_right = -80
	dialog_panel.visible = false
	canvas_layer.add_child(dialog_panel)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.0, 0.08, 0.95)
	style.border_color = Color(0.6, 0.0, 0.8)
	style.border_width_left   = 3
	style.border_width_top    = 3
	style.border_width_right  = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left     = 10
	style.corner_radius_top_right    = 10
	style.corner_radius_bottom_left  = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left   = 20
	style.content_margin_top    = 15
	style.content_margin_right  = 20
	style.content_margin_bottom = 15
	dialog_panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	dialog_panel.add_child(vbox)

	name_label = Label.new()
	name_label.text = npc_name
	name_label.add_theme_color_override("font_color", Color(0.7, 0.0, 0.9))
	name_label.add_theme_font_size_override("font_size", 22)
	vbox.add_child(name_label)

	var dialog_label_node = Label.new()
	dialog_label_node.add_theme_color_override("font_color", Color.WHITE)
	dialog_label_node.add_theme_font_size_override("font_size", 17)
	dialog_label_node.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(dialog_label_node)
	dialog_label = dialog_label_node

	# Кнопки выбора
	choice_container = HBoxContainer.new()
	choice_container.add_theme_constant_override("separation", 12)
	choice_container.visible = false
	vbox.add_child(choice_container)

	choice_btn_1 = Button.new()
	choice_btn_1.custom_minimum_size = Vector2(200, 48)
	choice_btn_1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choice_container.add_child(choice_btn_1)

	choice_btn_2 = Button.new()
	choice_btn_2.custom_minimum_size = Vector2(200, 48)
	choice_btn_2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choice_container.add_child(choice_btn_2)

func _input(event):
	if event.is_action_pressed("interact") and player_nearby and not dialog_open:
		_open_dialog()

func _open_dialog():
	dialog_open = true
	dialog_label.text = "Хахаха... ты победил моих слуг.\nНо сердце дерева у меня.\nОтдай его мне добровольно и я сохраню тебе жизнь.\nИли умри здесь!"
	dialog_panel.visible = true
	
	await get_tree().create_timer(0.5).timeout
	_show_choice()

func _show_choice():
	showing_choice = true
	choice_container.visible = true

	for c in choice_btn_1.pressed.get_connections():
		choice_btn_1.pressed.disconnect(c["callable"])
	for c in choice_btn_2.pressed.get_connections():
		choice_btn_2.pressed.disconnect(c["callable"])

	choice_btn_1.text = "💀 Отдать сердце вампиру"
	choice_btn_2.text = "⚔️ Отказать и сражаться!"

	choice_btn_1.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	choice_btn_2.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))

	choice_btn_1.pressed.connect(_choose_bad_ending)
	choice_btn_2.pressed.connect(_choose_good_ending)

func _choose_bad_ending():
	print("💀 Плохая концовка!")
	dialog_panel.visible = false
	GameState.current_ending = GameState.Ending.BAD
	_trigger_bad_ending()

func _choose_good_ending():
	print("⚔️ Хорошая концовка - бой с боссом!")
	dialog_panel.visible = false
	_trigger_boss_fight()

func _trigger_bad_ending():
	# Убиваем игрока
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.is_invincible = false
		player.can_move = false
		player.set_physics_process(false)

	# Затемнение
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 500
	get_tree().current_scene.add_child(overlay)

	var tw = create_tween()
	tw.tween_property(overlay, "color:a", 1.0, 2.0)
	await tw.finished

	# Показываем плохую концовку
	_show_ending_screen(false)

func _trigger_boss_fight():
	dialog_open = false

	var tw = create_tween()
	tw.tween_property(self, "modulate", Color(0.5, 0.0, 0.8), 0.5)
	tw.tween_property(self, "scale", Vector2(1.3, 1.3), 0.5)
	await tw.finished

	# Спавним финального босса на месте вампира
	_spawn_final_boss()

	# Скрываем вампира
	queue_free()

func _spawn_final_boss():
	var boss_scene = load("res://enemy/boss/final_boss/FinalBoss.tscn")
	if not boss_scene:
		print("❌ FinalBoss.tscn не найден!")
		return

	var boss = boss_scene.instantiate()
	boss.global_position = global_position
	get_tree().current_scene.add_child(boss)

	# Эффект появления
	boss.modulate.a = 0.0
	var tw = boss.create_tween()
	tw.tween_property(boss, "modulate:a", 1.0, 0.8)

	print("👹 Финальный босс появился!")

func _show_ending_screen(is_good: bool):
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	get_tree().current_scene.add_child(canvas)

	# Фон
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(bg)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.custom_minimum_size = Vector2(700, 400)
	vbox.position = Vector2(-350, -200)
	vbox.add_theme_constant_override("separation", 20)
	canvas.add_child(vbox)

	if not is_good:
		# ПЛОХАЯ КОНЦОВКА
		var title = Label.new()
		title.text = "КОНЕЦ"
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.add_theme_font_size_override("font_size", 52)
		title.add_theme_color_override("font_color", Color(0.8, 0.0, 0.0))
		title.add_theme_constant_override("outline_size", 3)
		title.add_theme_color_override("font_outline_color", Color.BLACK)
		title.modulate.a = 0.0
		vbox.add_child(title)

		var story = Label.new()
		story.text = "Ты отдал сердце дерева вампиру.\n\nВампир получил невероятную силу и поглотил\nсилу Священного Дерева.\n\nДеревня была уничтожена в ту же ночь.\nЛес погрузился во тьму навсегда.\n\nТы стал соучастником гибели мира..."
		story.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		story.autowrap_mode = TextServer.AUTOWRAP_WORD
		story.custom_minimum_size = Vector2(650, 0)
		story.add_theme_font_size_override("font_size", 16)
		story.add_theme_color_override("font_color", Color(0.8, 0.6, 0.6))
		story.modulate.a = 0.0
		vbox.add_child(story)

		var tw = create_tween()
		tw.tween_property(title, "modulate:a", 1.0, 1.5)
		tw.tween_property(story, "modulate:a", 1.0, 2.0)

		# Кнопка в меню
		await get_tree().create_timer(4.0).timeout
		_add_menu_button(canvas)

func _add_menu_button(canvas: CanvasLayer) -> void:
	var btn = Button.new()
	btn.text = "В главное меню"
	btn.custom_minimum_size = Vector2(220, 50)
	btn.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	btn.position = Vector2(-110, -80)
	btn.add_theme_font_size_override("font_size", 16)
	canvas.add_child(btn)

	btn.modulate.a = 0.0
	var tw = btn.create_tween()
	tw.tween_property(btn, "modulate:a", 1.0, 0.5)

	btn.pressed.connect(func():
		get_tree().change_scene_to_file("res://menu/menu.tscn")
	)

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_nearby = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_nearby = false
		if dialog_open:
			dialog_panel.visible = false
