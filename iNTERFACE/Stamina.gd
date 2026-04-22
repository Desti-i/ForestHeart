extends TextureProgressBar

func _ready() -> void:
	await get_tree().process_frame
	_connect_to_player()

func _connect_to_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	var player = null  # Объявляем ОДИН раз в начале
	
	if players.size() > 0:
		player = players[0]  # Убираем var
		if player.has_signal("stamina_changed"):
			player.stamina_changed.connect(Callable(self, "_on_stamina_changed"))
			max_value = player.max_stamina
			min_value = 0.0
			value = player.stamina
			return
	
	# Если не нашли через группу, ищем по имени
	player = get_tree().current_scene.find_child("Player", true, false)  # Убираем var
	if player and player.has_signal("stamina_changed"):
		player.stamina_changed.connect(Callable(self, "_on_stamina_changed"))
		max_value = player.max_stamina
		value = player.stamina

func _on_stamina_changed(cur: float, max_val: float) -> void:
	max_value = max_val
	value = cur
