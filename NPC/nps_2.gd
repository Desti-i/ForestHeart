extends CharacterBody2D

@export var npc_name: String = "Вампир"

@onready var animated_sprite = $AnimatedSprite2D

var player_nearby: bool = false
var dialog_open: bool = false
var current_line: int = 0
var dialog_lines: Array = []

# UI элементы
var canvas_layer: CanvasLayer
var dialog_panel: PanelContainer
var name_label: Label
var dialog_label: Label
var next_button: Button

func _ready():
	if not GameState.vampire_spawned:
		visible = false
		_set_collision_active(false)
		var area = $DetectionArea
		if area:
			area.monitoring = false
		return
	
	visible = true
	_setup()

func _setup():
	_set_collision_active(true)
	_create_ui()
	_update_dialog()
	
	var area = $DetectionArea
	if area:
		area.monitoring = true
		if not area.body_entered.is_connected(_on_body_entered):
			area.body_entered.connect(_on_body_entered)
		if not area.body_exited.is_connected(_on_body_exited):
			area.body_exited.connect(_on_body_exited)
	
	print("🧛 Вампир появился и готов говорить!")

func _set_collision_active(active: bool):
	set_collision_layer_value(1, active)
	set_collision_mask_value(1, active)
	
	var shape = $CollisionShape2D
	if shape:
		shape.disabled = not active

func _create_ui():
	canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 10
	add_child(canvas_layer)
	
	dialog_panel = PanelContainer.new()
	dialog_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	dialog_panel.offset_top = -200
	dialog_panel.offset_left = 100
	dialog_panel.offset_right = -100
	dialog_panel.visible = false
	canvas_layer.add_child(dialog_panel)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.0, 0.05, 0.95)
	style.border_color = Color(0.8, 0.0, 0.0)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	dialog_panel.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	dialog_panel.add_child(vbox)
	
	name_label = Label.new()
	name_label.text = npc_name
	name_label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2))
	name_label.add_theme_font_size_override("font_size", 22)
	vbox.add_child(name_label)
	
	dialog_label = Label.new()
	dialog_label.add_theme_color_override("font_color", Color.WHITE)
	dialog_label.add_theme_font_size_override("font_size", 18)
	dialog_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(dialog_label)
	
	next_button = Button.new()
	next_button.text = "Далее →"
	next_button.custom_minimum_size = Vector2(120, 40)
	next_button.pressed.connect(_on_next_pressed)
	vbox.add_child(next_button)

func _update_dialog():
	match GameState.quest_vampire:
		GameState.QuestState.NOT_TAKEN:
			dialog_lines = [
				"Приветствую, странник...",
				"Я видел, как тот злодей украл сердце дерева.",
				"Он побежал в лес гоблинов.",
				"Помоги моему племени...",
				"Эти проклятые гоблины мешают нам жить.",
				"Убей 10 гоблинов, что мешают мне вернуться домой",
				"Я покажу куда ушёл босс и открою тебе данж.",
				"Согласен помочь?"
			]
		GameState.QuestState.ACTIVE:
			var left = GameState.goblins_needed - GameState.goblins_killed
			dialog_lines = [
				"Ты ещё не убил всех гоблинов.",
				"Осталось уничтожить: " + str(left),
				"Возвращайся, когда сделаешь дело."
			]
		GameState.QuestState.COMPLETED:
			dialog_lines = [
				"Ты справился! Гоблины больше не угрожают нам!",
				"Спасибо тебе, герой!",
				"Как и обещал, вот ключ от второй локации.",
				"Иди и стань сильнее!"
			]
		GameState.QuestState.HANDED_IN:
			dialog_lines = [
				"Ты настоящий герой!",
				"Вторая локация теперь открыта для тебя.",
				"Возвращайся, если понадобится помощь."
			]
		_:
			dialog_lines = ["Что тебе нужно?"]

func _input(event):
	if event.is_action_pressed("interact") and player_nearby and not dialog_open and visible:
		_open_dialog()
	if event.is_action_pressed("ui_cancel") and dialog_open:
		_close_dialog()

func _open_dialog():
	dialog_open = true
	current_line = 0
	dialog_label.text = dialog_lines[current_line]
	dialog_panel.visible = true
	
	if len(dialog_lines) == 1:
		next_button.text = "Закрыть"
	else:
		next_button.text = "Далее →"

func _close_dialog():
	dialog_open = false
	dialog_panel.visible = false
	
	if GameState.quest_vampire == GameState.QuestState.NOT_TAKEN:
		GameState.start_vampire_quest()
		_show_notification("🧛 Квест принят! Убей 10 гоблинов!", Color.ORANGE)
		print("🧛 Квест принят!")
	elif GameState.quest_vampire == GameState.QuestState.COMPLETED:
		GameState.hand_in_vampire_quest()
		_show_notification("🗝️ ВТОРАЯ ЛОКАЦИЯ ОТКРЫТА! +500 EXP", Color.GREEN)
		print("🎉 Квест сдан! Вторая локация открыта!")
		await get_tree().create_timer(2.0).timeout
		queue_free()

func _on_next_pressed():
	if current_line + 1 < len(dialog_lines):
		current_line += 1
		dialog_label.text = dialog_lines[current_line]
		
		# Если это последняя строка, меняем текст кнопки
		if current_line == len(dialog_lines) - 1:
			if GameState.quest_vampire == GameState.QuestState.NOT_TAKEN:
				next_button.text = "Принять квест"
			elif GameState.quest_vampire == GameState.QuestState.COMPLETED:
				next_button.text = "Получить ключ"
			else:
				next_button.text = "Закрыть"
	else:
		_close_dialog()

func _restore_tree():
	var tree = get_tree().current_scene.find_child("HeartTree", true, false)
	if tree and tree.has_method("restore"):
		tree.restore()
		print("🌳 Дерево восстановлено!")

func _show_notification(msg: String, color: Color):
	var lbl = Label.new()
	lbl.text = msg
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_constant_override("outline_size", 2)
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.position = Vector2(150, 100)
	lbl.z_index = 200
	get_tree().current_scene.add_child(lbl)
	
	var tween = create_tween()
	tween.tween_property(lbl, "modulate:a", 0.0, 3.0)
	tween.tween_callback(lbl.queue_free)

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_nearby = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_nearby = false
		if dialog_open:
			_close_dialog()
			
func activate():
	visible = true
	_set_collision_active(true)
	_create_ui()
	_update_dialog()
	
	var area = $DetectionArea
	if area:
		area.monitoring = true
		if not area.body_entered.is_connected(_on_body_entered):
			area.body_entered.connect(_on_body_entered)
		if not area.body_exited.is_connected(_on_body_exited):
			area.body_exited.connect(_on_body_exited)
	
	print("🧛 Вампир активирован и готов к диалогу!")
