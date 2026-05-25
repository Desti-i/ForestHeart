extends Death

func enter():
	super()
	
	GameState.add_exp(enemy.exp_reward)
	
	# 🩸 Выпадение магии крови с босса
	if not GameState.blood_magic_unlocked:
		GameState.unlock_blood_magic()
		print("🩸 МАГИЯ КРОВИ ВЫПАЛА С БОССА!")
	
	# Отмечаем, что босс убит (портал откроется)
	GameState.boss_defeated = true
	print("👑 БОСС ПОБЕЖДЁН! Портал на 3 локацию открыт!")
	
	GameState.update_save_data()
