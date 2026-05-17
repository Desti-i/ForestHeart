extends Death

@export var ice_magic_drop_chance: float = 0.2  # Шанс 20% (можно настроить)

func enter():
	super()
	
	var random_value = randf()
	print("❄️ Шанс выпадения ледяной магии: ", ice_magic_drop_chance, " | Выпало: ", random_value)
	
	if not GameState.ice_magic_unlocked and random_value <= ice_magic_drop_chance:
		GameState.unlock_ice_magic()
		print("❄️ ЛЕДЯНАЯ МАГИЯ ВЫПАЛА С ЛЕДЯНОЙ СЛИЗИ!")
	else:
		print("❄️ Ледяная магия НЕ выпала в этот раз")
