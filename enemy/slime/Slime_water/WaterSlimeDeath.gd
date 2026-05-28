extends Death

@export var water_magic_drop_chance: float = 0.03 # Шанс 3%

func enter():
	super()
	
	var random_value = randf()
	
	if not GameState.water_magic_unlocked and random_value <= water_magic_drop_chance:
		GameState.unlock_water_magic()
