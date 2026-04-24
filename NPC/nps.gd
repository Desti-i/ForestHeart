extends CharacterBody2D

@export var npc_name: String = "Старейшина"
@export var dialog_lines: Array[String] = [
	"Привет, путник!",
	"Слышал я про орков в лесу...",
	"Помоги нам избавиться от них!",
	"Возвращайся, когда справишься."
]

@onready var animated_sprite = $AnimatedSprite2D

var current_line: int = 0
var player_nearby: bool = false
var dialog_open: bool = false

# UI элементы
var canvas_layer: CanvasLayer
var dialog_panel: PanelContainer
var name_label: Label
var dialog_label: Label
var next_button: Button

func _ready():
	_create_ui()
	
	if animated_sprite:
		animated_sprite.play("idle")
	
	# ВАЖНО: Сбрасываем состояние при старте
	player_nearby = false
	
	# Небольшая задержка для проверки (чтобы игрок успел появиться)
	await get_tree().process_frame
	_check_initial_player_in_zone()
	
	print("NPC готов!")

# Проверяем, не стоит ли игрок уже в зоне при старте
func _check_initial_player_in_zone():
	var bodies = $DetectionArea.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("player"):
			# Игрок в зоне при старте - игнорируем, нужно чтобы он вышел и зашёл заново
			print("⚠️ Игрок уже в зоне при старте! Нужно выйти и зайти заново.")
			player_nearby = false
			return
	player_nearby = false
	print("✅ Стартовая позиция игрока вне зоны NPC")

func _input(event):
	if event.is_action_pressed("interact") and player_nearby and not dialog_open:
		print("Игрок рядом и нажал E! Открываем диалог")
		_open_dialog()
	
	if event.is_action_pressed("ui_cancel") and dialog_open:
		_close_dialog()

func _create_ui():
	# CanvasLayer
	canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 10
	add_child(canvas_layer)
	
	# PanelContainer
	dialog_panel = PanelContainer.new()
	dialog_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	dialog_panel.offset_top = -200
	dialog_panel.offset_left = 100
	dialog_panel.offset_right = -100
	dialog_panel.visible = false
	canvas_layer.add_child(dialog_panel)
	
	# Стиль панели
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.9)
	style.border_width_left = 3
	style.border_width_top = 3
	style.border_width_right = 3
	style.border_width_bottom = 3
	style.border_color = Color.WHITE
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 20
	style.content_margin_top = 15
	style.content_margin_right = 20
	style.content_margin_bottom = 15
	
	dialog_panel.add_theme_stylebox_override("panel", style)
	
	# VBoxContainer
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	dialog_panel.add_child(vbox)
	
	# NameLabel
	name_label = Label.new()
	name_label.text = npc_name
	name_label.add_theme_color_override("font_color", Color.YELLOW)
	name_label.add_theme_font_size_override("font_size", 22)
	vbox.add_child(name_label)
	
	# DialogLabel
	dialog_label = Label.new()
	dialog_label.add_theme_color_override("font_color", Color.WHITE)
	dialog_label.add_theme_font_size_override("font_size", 18)
	dialog_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(dialog_label)
	
	# NextButton
	next_button = Button.new()
	next_button.text = "Далее →"
	next_button.custom_minimum_size = Vector2(120, 40)
	next_button.pressed.connect(_on_next_button_pressed)
	vbox.add_child(next_button)
	
	print("✓ UI создан программно!")

func _open_dialog():
	dialog_open = true
	current_line = 0
	dialog_label.text = dialog_lines[current_line]
	dialog_panel.visible = true
	print("✓ Диалог открыт!")

func _close_dialog():
	dialog_open = false
	dialog_panel.visible = false
	current_line = 0
	next_button.text = "Далее →"
	print("✗ Диалог закрыт")

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = true
		print("✅ Игрок вошёл в зону! Нажми E для диалога")

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = false
		print("❌ Игрок покинул зону")
		if dialog_open:
			_close_dialog()

func _on_next_button_pressed() -> void:
	current_line += 1
	
	if current_line < dialog_lines.size():
		dialog_label.text = dialog_lines[current_line]
		
		if current_line == dialog_lines.size() - 1:
			next_button.text = "Закрыть"
	else:
		_close_dialog()
