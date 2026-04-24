extends Area2D

var speed: float
var direction: Vector2
var damage: float
var target_position: Vector2

func _ready():
	if direction != Vector2.ZERO:
		rotation = direction.angle() - PI/2

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	
	if position.distance_to(target_position) < 10:
		queue_free()
	
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)
	
