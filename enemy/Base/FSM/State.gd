extends Node
class_name State # Базовое состояние

var enemy  # Ссылка на врага
var state_machine  # Ссылка на FSM

func enter():  # вход
	pass

func update(_delta):  # логика
	pass	

func exit():  # Выход
	pass
