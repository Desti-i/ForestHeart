extends Label
 
func _ready() -> void:
	GameState.exp_changed.connect(_on_exp_changed)
	text = "⭐ " + str(GameState.exp) + " EXP"
 
func _on_exp_changed(new_amount: int) -> void:
	text = "⭐ " + str(new_amount) + " EXP"
 
