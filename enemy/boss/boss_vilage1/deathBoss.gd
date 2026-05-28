extends Death

func enter():
	super()
	
	# Отмечаем, что босс убит открываем портал на локацию
	GameState.boss_defeated = true
	
	GameState.update_save_data()
