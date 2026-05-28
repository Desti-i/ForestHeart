extends Node2D

# ── Символы ───────────────────────────────────────────────
const SYMBOLS     = ["7", "★", "☠", "◆", "†", "●"]
const WEIGHTS     = [5,   15,   15,   15,   25,  25]
const SPIN_COST   = 200

# ── Узлы ──────────────────────────────────────────────────
@onready var reel1        = $CanvasLayer/Reel1
@onready var reel2        = $CanvasLayer/Reel2
@onready var reel3        = $CanvasLayer/Reel3
@onready var result_label = $CanvasLayer/ResultLabel
@onready var exp_label    = $CanvasLayer/ExpLabel
@onready var spin_button  = $CanvasLayer/SpinButton
@onready var area         = $Area2D

# ── Состояние ─────────────────────────────────────────────
var _spinning:      bool  = false
var _player_nearby: bool  = false
var _ui_open:       bool  = false
var _final_syms:    Array = ["7", "7", "7"]


const SVG_W = 300.0
const SVG_H = 460.0
const OX    = -SVG_W / 2.0   # -150
const OY    = -SVG_H / 2.0   # -230

func _create_sign() -> void:
	var sign = Label.new()
	sign.text = "✨ МАГИЧЕСКОЕ КАЗИНО ✨"
	sign.add_theme_font_size_override("font_size", 14)
	sign.add_theme_color_override("font_color", Color(0.94, 0.75, 0.25))
	sign.add_theme_constant_override("outline_size", 2)
	sign.add_theme_color_override("font_outline_color", Color.BLACK)
	sign.position = Vector2(-220, -260)  
	sign.z_index = 10
	add_child(sign)
	
	# Мигание
	var tw = create_tween()
	tw.set_loops()
	tw.tween_property(sign, "modulate:a", 0.3, 0.8)
	tw.tween_property(sign, "modulate:a", 1.0, 0.8)

func _ready() -> void:
	_setup_ui()
	_setup_collision()
	_create_sign() 
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	spin_button.pressed.connect(_on_spin_pressed)
	GameState.exp_changed.connect(_on_exp_changed)
	_hide_ui()
	

func _setup_ui() -> void:

	var cx = 576.0  
	var cy = 324.0  

	# ── Барабаны ─────────────────────────────────────────
	
	_style_reel(reel1, cx - 150 + 22,  cy - 230 + 130)
	_style_reel(reel2, cx - 150 + 111, cy - 230 + 130)
	_style_reel(reel3, cx - 150 + 200, cy - 230 + 130)

	reel1.text = "7"
	reel2.text = "7"
	reel3.text = "7"

	# ── Результат ────────────────────────────────────────
	result_label.text = "Удачи, путник!"
	result_label.add_theme_font_size_override("font_size", 13)
	result_label.add_theme_color_override("font_color", Color(0.94, 0.75, 0.25))
	result_label.position = Vector2(cx - 150 + 15, cy - 230 + 228)
	result_label.custom_minimum_size = Vector2(270, 30)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# ── EXP ──────────────────────────────────────────────
	exp_label.text = "EXP: " + str(GameState.exp)
	exp_label.add_theme_font_size_override("font_size", 13)
	exp_label.add_theme_color_override("font_color", Color(0.63, 0.88, 0.38))
	exp_label.position = Vector2(cx - 150 + 157, cy - 230 + 272)
	exp_label.custom_minimum_size = Vector2(128, 30)
	exp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# ── Кнопка ───────────────────────────────────────────
	spin_button.text = "КРУТИТЬ  [E]"
	spin_button.add_theme_font_size_override("font_size", 15)
	spin_button.position = Vector2(cx - 150 + 35, cy - 230 + 310)
	spin_button.custom_minimum_size = Vector2(230, 52)

	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.35, 0.23, 0.62)
	style_normal.corner_radius_top_left     = 12
	style_normal.corner_radius_top_right    = 12
	style_normal.corner_radius_bottom_left  = 12
	style_normal.corner_radius_bottom_right = 12
	style_normal.border_width_left   = 2
	style_normal.border_width_top    = 2
	style_normal.border_width_right  = 2
	style_normal.border_width_bottom = 2
	style_normal.border_color = Color(0.48, 0.35, 0.75)
	spin_button.add_theme_stylebox_override("normal", style_normal)
	spin_button.add_theme_color_override("font_color", Color.WHITE)

func _style_reel(lbl: Label, x: float, y: float) -> void:
	lbl.add_theme_font_size_override("font_size", 32)
	lbl.add_theme_color_override("font_color", Color(0.94, 0.75, 0.25))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.custom_minimum_size  = Vector2(74, 40)
	lbl.position = Vector2(x, y)

func _setup_collision() -> void:
	var shape = RectangleShape2D.new()
	shape.size = Vector2(SVG_W, SVG_H)
	$Area2D/CollisionShape2D.shape = shape

# ── Взаимодействие ────────────────────────────────────────
func _process(_delta) -> void:
	if Input.is_action_just_pressed("interact") and _player_nearby and not _spinning:
		if not _ui_open:
			_show_ui()
		else:
			_hide_ui()

func _show_ui() -> void:
	_ui_open = true
	reel1.visible        = true
	reel2.visible        = true
	reel3.visible        = true
	result_label.visible = true
	exp_label.visible    = true
	spin_button.visible  = true
	exp_label.text = "EXP: " + str(GameState.exp)

func _hide_ui() -> void:
	_ui_open = false
	reel1.visible        = false
	reel2.visible        = false
	reel3.visible        = false
	result_label.visible = false
	exp_label.visible    = false
	spin_button.visible  = false

# ── Спин ──────────────────────────────────────────────────
func _on_spin_pressed() -> void:
	if _spinning:
		return
	if GameState.exp < SPIN_COST:
		result_label.text = "Не хватает EXP!"
		_shake_label(result_label)
		return

	GameState.spend_exp(SPIN_COST)
	_spinning = true
	spin_button.disabled = true
	result_label.text    = "..."

	_final_syms = [_weighted_rand(), _weighted_rand(), _weighted_rand()]

	_animate_reel(reel1, _final_syms[0], 0.8)
	_animate_reel(reel2, _final_syms[1], 1.1)
	_animate_reel(reel3, _final_syms[2], 1.4)

	await get_tree().create_timer(1.6).timeout
	_finalize()

func _animate_reel(lbl: Label, final_sym: String, duration: float) -> void:
	var elapsed  = 0.0
	var interval = 0.07

	while elapsed < duration - 0.15:
		lbl.text  = _weighted_rand()
		await get_tree().create_timer(interval).timeout
		elapsed  += interval
		if elapsed > duration * 0.65:
			interval = lerpf(interval, 0.18, 0.12)

	lbl.text = final_sym
	var tw = create_tween()
	tw.tween_property(lbl, "scale", Vector2(1.3, 1.3), 0.08)
	tw.tween_property(lbl, "scale", Vector2(1.0, 1.0), 0.08)

func _finalize() -> void:
	_spinning            = false
	spin_button.disabled = false

	var s    = _final_syms
	var mult = 0
	var msg  = ""

	if s[0] == s[1] and s[1] == s[2]:
		match s[0]:
			"7":  mult = 20; msg = "ДЖЕКПОТ! x20! 🎉"
			"★":  mult = 10; msg = "ТРИ ЗВЕЗДЫ! x10!"
			"☠":  mult = 8;  msg = "ТРИ ЧЕРЕПА! x8!"
			"◆":  mult = 5;  msg = "ТРИ АЛМАЗА! x5!"
			_:    mult = 3;  msg = "ТРИ В РЯД! x3!"
	elif s[0]==s[1] or s[1]==s[2] or s[0]==s[2]:
		mult = 1; msg = "ДВА СОВПАДЕНИЯ! x1"
	else:
		mult = 0; msg = "Не повезло..."

	if mult > 0:
		var win = SPIN_COST * mult
		GameState.add_exp(win)
		result_label.text = msg + " +" + str(win) + " EXP"
		_flash_reels()
	else:
		result_label.text = msg

	exp_label.text = "EXP: " + str(GameState.exp)

# ── Визуальные эффекты ────────────────────────────────────
func _flash_reels() -> void:
	for lbl in [reel1, reel2, reel3]:
		var tw = create_tween()
		tw.tween_property(lbl, "modulate", Color(1.0, 0.9, 0.2), 0.1)
		tw.tween_property(lbl, "modulate", Color.WHITE, 0.1)
		tw.tween_property(lbl, "modulate", Color(1.0, 0.9, 0.2), 0.1)
		tw.tween_property(lbl, "modulate", Color.WHITE, 0.1)

func _shake_label(lbl: Label) -> void:
	var orig = lbl.position
	var tw   = create_tween()
	tw.tween_property(lbl, "position", orig + Vector2(-5, 0), 0.05)
	tw.tween_property(lbl, "position", orig + Vector2(5, 0),  0.05)
	tw.tween_property(lbl, "position", orig + Vector2(-4, 0), 0.05)
	tw.tween_property(lbl, "position", orig, 0.05)


func _weighted_rand() -> String:
	var total = 0
	for w in WEIGHTS: total += w
	var r = randi() % total
	for i in SYMBOLS.size():
		r -= WEIGHTS[i]
		if r < 0: return SYMBOLS[i]
	return SYMBOLS[SYMBOLS.size() - 1]

func _on_exp_changed(amount: int) -> void:
	if _ui_open:
		exp_label.text = "EXP: " + str(amount)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_nearby = true
		print("🎰 Подойди и нажми E чтобы открыть казино")

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_nearby = false
		_hide_ui()
