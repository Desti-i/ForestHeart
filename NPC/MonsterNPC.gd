extends CharacterBody2D

@onready var animated_sprite = $AnimatedSprite2D

func _ready():
	if animated_sprite:
		animated_sprite.play("idle")
	
	# Исчезаем через 5 секунд
	await get_tree().create_timer(5.0).timeout
	
	# Анимация исчезновения
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 1.0)
	await tween.finished
	queue_free()
