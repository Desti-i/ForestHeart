extends StaticBody2D

var state: String = "Idle_1"

@export var time_1: float = 5
@export var time_2: float = 5
@export var two_anim: bool = true

@onready var anim = $AnimatedSprite2D

func _process(_delta: float) -> void:
	if two_anim:
		if state == "Idle_1":
			anim.play(state)
			await get_tree().create_timer(time_1).timeout
			state = "Idle_2"
		else:
			anim.play(state)
			await get_tree().create_timer(time_2).timeout
			state = "Idle_1"
	else:
		anim.play(state)
		await get_tree().create_timer(time_1).timeout
