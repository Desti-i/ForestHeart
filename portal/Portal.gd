extends Area2D

@export var next_scene: String = "res://locations/location_2/location_2.tscn"

func _ready() -> void:
	print("🟣 ПОРТАЛ ЗАПУЩЕН!")
	monitoring = true
	collision_mask = 0xFFFFFFFF
	
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	print("🔴 ВОШЁЛ:", body.name)
	if body.is_in_group("player"):
		print("🌀 ПЕРЕХОД!")
		get_tree().call_deferred("change_scene_to_file", next_scene)
