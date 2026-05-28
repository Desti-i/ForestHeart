extends Death

@export var ice_magic_drop_chance: float = 0.1  # Шанс 10%

func enter():
	super()
	
	var random_value = randf()
	
	if not GameState.ice_magic_unlocked and random_value <= ice_magic_drop_chance:
		GameState.unlock_ice_magic()
