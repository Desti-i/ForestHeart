extends Control

@onready var health_bar = $HPBar
@onready var health_label = $HPBar/Label  # если есть

var player: CharacterBody2D
var max_health: float = 20

func _ready():
	# Ищем игрока
	player = get_tree().get_first_node_in_group("player")
	
	if player:
		max_health = player.heals
		health_bar.max_value = max_health
		health_bar.value = player.heals
		
		# ========== ДОБАВЬТЕ ЭТОТ КОД ЗДЕСЬ ==========
		setup_style()  # ← Вызов функции стилизации
		# ===========================================
		
		if health_label:
			health_label.text = str(player.heals, "/", max_health)
		
		if player.has_signal("health_changed"):
			player.health_changed.connect(_on_health_changed)
	else:
		print("Player not found!")

# ========== ДОБАВЬТЕ ЭТУ ФУНКЦИЮ В КОНЕЦ ФАЙЛА ==========
func setup_style():
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.2)  # Тёмный фон
	style.set_border_width_all(2)
	style.border_color = Color(0.5, 0.5, 0.5)
	health_bar.add_theme_stylebox_override("background", style)
	
	var style_fill = StyleBoxFlat.new()
	style_fill.bg_color = Color(0.2, 0.8, 0.2)  # Зелёная заливка
	health_bar.add_theme_stylebox_override("fill", style_fill)
# =====================================================

func update_health_display(current_health: float):
	health_bar.value = current_health
	if health_label:
		health_label.text = str(round(current_health), "/", max_health)

func _on_health_changed(new_health: float, new_max_health: float):
	max_health = new_max_health
	update_health_display(new_health)
