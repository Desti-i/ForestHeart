extends CharacterBody2D

@export var npc_name: String = "Таинственный странник"

@onready var animated_sprite = $AnimatedSprite2D

var player_nearby: bool = false
var dialog_open: bool = false
var current_line: int = 0
var dialog_lines: Array = []

var canvas_layer: CanvasLayer
var dialog_panel: PanelContainer
var name_label: Label
var dialog_label: Label
var next_button: Button

func _ready():
	_create_ui()
	if animated_sprite:
		animated_sprite.play("idle")
	
	_setup_dialog()
	
	var area = $DetectionArea
	if area:
		area.body_entered.connect(_on_body_entered)
		area.body_exited.connect(_on_body_exited)
	
func _setup_dialog():
	dialog_lines = [
		"О, путник! Ты пришёл вовремя.",
		"Слушай внимательно, это важная информация.",
		"Впереди находится древнее ПОДЗЕМЕЛЬЕ.",
		"Чтобы пройти в проход, нужно заплатить стражнику.",
		"Также на карте есть КОМНАТА АЗАРТА.",
		"🎰 Обязательно зайди в неё!",
		"Ты сможешь получить 2 мощные магии:",
		"Они выпадат тебе с ледяных и водных слизей.",
		"А так же сможешь получить новый меч, убив огненных слизей!",
		"⚔️ Он очень сильный, не упусти шанс.",
		"Но будь осторожен...",
		"👑 В конце подземелья тебя ждёт БОСС ВАМПИРОВ.",
		"Он тоже ищет сердце Древа.",
		"Убей его и сможешь попасть на следующую локацию.",
		"Удачи, путник! Я верю в тебя."
	]

func _create_ui():
	canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 10
	add_child(canvas_layer)

	dialog_panel = PanelContainer.new()
	dialog_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	dialog_panel.offset_top = -220
	dialog_panel.offset_left = 100
	dialog_panel.offset_right = -100
	dialog_panel.visible = false
	canvas_layer.add_child(dialog_panel)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.1, 0.95)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = Color(0.5, 0.8, 1.0)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	dialog_panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	dialog_panel.add_child(vbox)

	name_label = Label.new()
	name_label.text = npc_name
	name_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
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

func _input(event):
	if event.is_action_pressed("interact") and player_nearby and not dialog_open:
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
	current_line = 0
	next_button.text = "Далее →"

func _on_next_pressed():
	if current_line + 1 < len(dialog_lines):
		current_line += 1
		dialog_label.text = dialog_lines[current_line]
		
		# Если это последняя строка
		if current_line == len(dialog_lines) - 1:
			next_button.text = "Закрыть"
	else:
		_close_dialog()

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_nearby = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_nearby = false
		if dialog_open:
			_close_dialog() 
