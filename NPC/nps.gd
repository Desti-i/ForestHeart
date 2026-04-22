extends CharacterBody2D

# Настройки NPC
@export var npc_name: String = "Старейшина"
@export var dialog_lines: Array[String] = [
	"Привет, путник!",
	"Слышал я про орков в лесу...",
	"Они стали слишком опасными.",
	"Помоги нам избавиться от них!",
	"Возвращайся, когда справишься."
]

# Ссылки на узлы
@onready var animated_sprite = $AnimatedSprite2D
@onready var dialog_panel = $CanvasLayer/PanelContainer
@onready var name_label = $CanvasLayer/PanelContainer/VBoxContainer/NameLabel
@onready var dialog_label = $CanvasLayer/PanelContainer/VBoxContainer/DialogLabel
@onready var next_button = $CanvasLayer/PanelContainer/NextButton

# Переменные состояния
var current_line: int = 0
var player_nearby: bool = false
var dialog_open: bool = false

func _ready():
	dialog_panel.visible = false
	name_label.text = npc_name
	if animated_sprite:
		animated_sprite.play("idle")

func _input(event):
	# Отладка
	if event.is_action_pressed("ui_accept"):
		print("E нажата! player_nearby=", player_nearby, " dialog_open=", dialog_open)
	
	if event.is_action_pressed("ui_accept") and player_nearby and not dialog_open:
		print("Условия выполнены! Открываем диалог!")
		_open_dialog()
	
	if event.is_action_pressed("ui_cancel") and dialog_open:
		_close_dialog()

func _open_dialog():
	print("DIALOG OPEN - вызывается!")
	dialog_open = true
	current_line = 0
	dialog_label.text = dialog_lines[current_line]
	dialog_panel.visible = true
	# Убрал паузу

func _close_dialog():
	print("DIALOG CLOSE - вызывается!")
	dialog_open = false
	dialog_panel.visible = false
	next_button.text = "Далее →"
	# Убрал паузу

func _on_deteccion_area_body_entered(body: Node2D) -> void:
	print("Кто-то вошёл в зону! ", body.name)
	if body.is_in_group("player"):
		print("ИГРОК В ЗОНЕ!")
		player_nearby = true

func _on_deteccion_area_body_exited(body: Node2D) -> void:
	print("Кто-то вышел из зоны!")
	if body.is_in_group("player"):
		print("ИГРОК ВЫШЕЛ!")
		player_nearby = false
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
