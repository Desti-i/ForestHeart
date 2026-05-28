extends Area2D

var damage := 20

func _ready():
	$AnimationPlayer.play("meteor")
	$AudioStreamPlayer2D.play()

	await $AnimationPlayer.animation_finished

	queue_free()

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.take_damage(damage)
