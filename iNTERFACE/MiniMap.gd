# Создать MiniMap.gd:
extends Control

@onready var minimap_viewport = $SubViewportContainer/SubViewport
@onready var minimap_camera = $SubViewportContainer/SubViewport/MinimapCamera

var player_node: Node2D = null

func _ready():
	await get_tree().process_frame
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_node = players[0]

func _process(_delta):
	if player_node and minimap_camera:
		minimap_camera.global_position = player_node.global_position
