extends Area2D

@onready var anim = $AnimationPlayer
@onready var label = $Label

var player_inside = false

var bets = [50, 100, 250]
var current_bet_index = 0

var is_spinning = false

func _ready():
	update_label()

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_inside = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_inside = false

func _process(delta):
	if not player_inside:
		return

	# Смена ставки
	if Input.is_action_just_pressed("ui_left"):
		current_bet_index = max(0, current_bet_index - 1)
		update_label()

	if Input.is_action_just_pressed("ui_right"):
		current_bet_index = min(bets.size() - 1, current_bet_index + 1)
		update_label()

	# Крутка
	if Input.is_action_just_pressed("interact"):
		spin()

# 🎰 ОБНОВЛЕНИЕ ТЕКСТА
func update_label():
	label.text = "Ставка: " + str(bets[current_bet_index]) + " EXP"

# 🎲 КАЗИНО
func spin():
	if is_spinning:
		return

	var bet = bets[current_bet_index]

	if not GameState.spend_exp(bet):
		label.text = "❌ Мало EXP"
		return

	is_spinning = true

	label.text = "🎰 КРУТКА..."
	anim.play("spin")

	await anim.animation_finished

	var roll = randf()

	if roll < 0.5:
		label.text = "💀 Проигрыш"
	elif roll < 0.85:
		var win = bet * 2
		GameState.add_exp(win)
		label.text = "💰 x2: " + str(win)
	else:
		var win = bet * 5
		GameState.add_exp(win)
		label.text = "🔥 JACKPOT: " + str(win)

	is_spinning = false
