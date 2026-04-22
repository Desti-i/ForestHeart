extends TextureProgressBar

@onready var stamina_label = $Label

func _ready() -> void:
	await get_tree().process_frame
	_connect_to_player()
	
	# Настройка внешнего вида текста
	if stamina_label:
		# Золотисто-желтый цвет для стамины
		stamina_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
		# Черная обводка для читаемости
		stamina_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
		stamina_label.add_theme_constant_override("outline_size", 1)

func _connect_to_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	var player = null
	
	if players.size() > 0:
		player = players[0]
		if player.has_signal("stamina_changed"):
			player.stamina_changed.connect(_on_stamina_changed)
			max_value = player.max_stamina
			min_value = 0.0
			value = player.stamina
			_update_label(player.stamina, player.max_stamina)
			return
	
	player = get_tree().current_scene.find_child("Player", true, false)
	if player and player.has_signal("stamina_changed"):
		player.stamina_changed.connect(_on_stamina_changed)
		max_value = player.max_stamina
		value = player.stamina
		_update_label(player.stamina, player.max_stamina)

func _on_stamina_changed(cur: float, max_val: float) -> void:
	max_value = max_val
	value = cur
	_update_label(cur, max_val)

func _update_label(current: float, maximum: float) -> void:
	if stamina_label:
		stamina_label.text = str(int(current)) + " / " + str(int(maximum))
		
		# Меняем цвет в зависимости от количества стамины
		var stamina_percent = current / maximum
		
		if stamina_percent <= 0.1:
			# Меньше 10% - красный (опасно, нельзя бежать)
			stamina_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
		elif stamina_percent <= 0.3:
			# Меньше 30% - оранжевый (предупреждение)
			stamina_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.2))
		else:
			# Больше 30% - золотистый (норма)
			stamina_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
