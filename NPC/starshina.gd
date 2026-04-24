extends Node2D

@onready var dialog_label = $Label

@export var dialog_text: String = "Привет, путник!"

func _ready():
	dialog_label.visible = false
	dialog_label.text = dialog_text

func _on_Area2D_body_entered(body):
	print("Сработало!")
	if body.is_in_group("player"):
		dialog_label.visible = true

func _on_Area2D_body_exited(body):
	if body.is_in_group("player"):
		dialog_label.visible = false
