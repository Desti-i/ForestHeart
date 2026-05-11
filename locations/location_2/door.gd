extends Node2D

@export var cost := 10
var player_in_range = false
var opened = false

func _process(delta):
	if player_in_range and Input.is_action_just_pressed("ui_accept") and !opened:
		try_open()

func try_open():
	if Global.exp >= cost:
		Global.exp -= cost
		open_door()
	else:
		print("Недостаточно EXP")

func open_door():
	opened = true
	$Sprite2D.visible = false
	$CollisionShape2D.disabled = true
	$Label.visible = false

func _on_area_2d_body_entered(body: Node2D) -> void:
	pass # Replace with function body.


func _on_area_2d_body_exited(body: Node2D) -> void:
	pass # Replace with function body.
