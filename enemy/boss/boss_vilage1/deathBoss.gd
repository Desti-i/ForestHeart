extends Death

func enter():
	super()
	
	# Отмечаем, что босс убит (портал откроется)
	GameState.boss_defeated = true
	print("👑 БОСС ПОБЕЖДЁН! Портал на 3 локацию открыт!")
	
	GameState.update_save_data()
