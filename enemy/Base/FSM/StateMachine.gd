extends Node

var states = {}  # Словарь всех состояний
var current_state = null  # Текущее состояние
var enemy  # Ссылка на врага

func init(enemy_ref) -> void: 
	enemy = enemy_ref
	
	for child in get_children():
		if child is State:
			states[child.name] = child
			child.enemy = enemy
			child.state_machine = self

	change_state("Idle")

func change_state(state_name: String) -> void:  # Функция смены состояния
	if current_state and current_state.name == state_name:
		return
	
	if current_state:
		current_state.exit()
	
	current_state = states.get(state_name)
	current_state.enter()

func update(delta) -> void:
	if current_state:
		current_state.update(delta)
		
