extends Death

func enter():
	super()
	
	GameState.add_exp(enemy.exp_reward)
	
	# Выпадение магии крови с босса
	if not GameState.blood_magic_unlocked:
		GameState.unlock_blood_magic()
	
	# Отмечаем, что босс убит -  портал откроется
	GameState.boss_defeated = true
	
	GameState.update_save_data()
