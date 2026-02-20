extends CharacterBody2D

enum DIRECTION { DOWN, UP, LEFT, RIGHT }

@onready var anim = $Move_mob

const SPEED = 70
var idle_dir: DIRECTION = DIRECTION.DOWN
var input_direction = Vector2.ZERO
var player = null

func _physics_process(_delta: float) -> void:
	if player:
		input_direction = (player.position - position).normalized()
		velocity = input_direction * SPEED
		move_and_slide()
		
	else:
		velocity = Vector2.ZERO
	
	handle_animation()
	
func handle_animation() -> void:
	if player:
		if abs(input_direction.x) > abs(input_direction.y):
			if input_direction.x > 0:
				anim.flip_h = true
				anim.play("Front")
				idle_dir = DIRECTION.RIGHT
			else:
				anim.flip_h = false
				anim.play("Front")
				idle_dir = DIRECTION.LEFT
		else:
			if input_direction.y > 0:
				anim.play("Down")
				idle_dir = DIRECTION.DOWN
			else:
				anim.play("Up")
				idle_dir = DIRECTION.UP
	else:
		match idle_dir:
			DIRECTION.DOWN:
				anim.play("idle_down")
			DIRECTION.UP:
				anim.play("idle_up")
			DIRECTION.LEFT:
				anim.flip_h = false
				anim.play("idle_front")
			DIRECTION.RIGHT:
				anim.flip_h = true
				anim.play("idle_front")


func _on_ditector_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player = body


func _on_ditector_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player = null
