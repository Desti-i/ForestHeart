extends Node

var states = {}  # Словарь всех состояний
var current_state = null  # Текущее состояние
var enemy  # Ссылка на врага

func init(enemy_ref) -> void:  # Инициализация FSM
	enemy = enemy_ref
	states = {
		"Idle": $Idle,
		"Chase": $Chase,
		"Attack": $Attack,
		"RangedAttack": $RangedAttack,
		"Death": $Death
	}
	
	for state in states.values():
		state.enemy = enemy
		state.state_machine = self

	change_state("Idle")

func change_state(state_name: String) -> void:  # Функция смены состояния
	if current_state:  # Выход из прошлого состояния
		current_state.exit()
	current_state = states[state_name]
	current_state.enter()

func update(delta) -> void:
	if current_state:
		current_state.update(delta)
		
