extends Area2D

var direction := Vector2.ZERO
var speed := 100
var damage := 20

func _physics_process(delta):

	$AnimatedSprite2D.play("sword")
	position += direction * speed * delta

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.take_damage(damage)

	queue_free()
