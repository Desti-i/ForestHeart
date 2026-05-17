extends Death

@export var water_magic_drop_chance: float = 0.05

func enter():
	super()
	
	var random_value = randf()
	print("💧 Шанс выпадения магии воды: ", water_magic_drop_chance, " | Выпало: ", random_value)
	
	if not GameState.water_magic_unlocked and random_value <= water_magic_drop_chance:
		GameState.unlock_water_magic()
		print("💧 МАГИЯ ВОДЫ ВЫПАЛА С ВОДНОЙ СЛИЗИ!")
	else:
		print("💧 Магия воды НЕ выпала в этот раз")
