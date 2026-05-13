extends Area2D

var level: int = 1
var damage: float = 18.0
var speed: float = 350.0
var direction: Vector2 = Vector2.RIGHT
var _lifetime: float = 0.0
var _angle: float = 0.0
var _trail: Array = []
var _hit_bodies: Array = []  # для уровня 4 - заморозка

const LEVEL_DATA = {
	1: { "radius": 6.0,  "speed": 350.0, "damage": 18.0,  "max_life": 1.8 },
	2: { "radius": 12.0, "speed": 280.0, "damage": 35.0,  "max_life": 2.2 },
	3: { "radius": 9.0,  "speed": 320.0, "damage": 60.0,  "max_life": 2.0 },
	4: { "radius": 16.0, "speed": 260.0, "damage": 95.0,  "max_life": 2.5 },
}
var _max_lifetime: float = 1.8
var _slow_duration: float = 2.0  # длительность замедления

func setup(lvl: int, dir: Vector2) -> void:
	level     = lvl
	direction = dir.normalized()
	var data  = LEVEL_DATA[lvl]
	speed     = data["speed"]
	damage    = data["damage"]
	_max_lifetime = data["max_life"]

func _ready() -> void:
	collision_layer = 0
	collision_mask  = 0b00000110
	monitoring = true
	body_entered.connect(_on_body_entered)

	var shape = CircleShape2D.new()
	shape.radius = LEVEL_DATA[level]["radius"]
	var col = CollisionShape2D.new()
	col.shape = shape
	add_child(col)

	scale = Vector2.ZERO
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector2.ONE, 0.08)

func _draw() -> void:
	var t = _lifetime
	match level:
		1: _draw_ice_shard(t)
		2: _draw_ice_block(t)
		3: _draw_ice_storm(t)
		4: _draw_absolute_zero(t)

# ── Уровень 1: острый ледяной осколок ────────────────────
func _draw_ice_shard(t: float) -> void:
	var r = LEVEL_DATA[1]["radius"]

	# Хвост
	for i in _trail.size():
		var alpha = float(i) / _trail.size() * 0.4
		var size  = r * (float(i) / _trail.size()) * 0.6
		var lp    = _trail[i] - global_position
		draw_circle(lp, size, Color(0.7, 0.95, 1.0, alpha))

	# Свечение
	draw_circle(Vector2.ZERO, r * 2.0, Color(0.7, 0.95, 1.0, 0.08))
	draw_circle(Vector2.ZERO, r * 1.4, Color(0.6, 0.9,  1.0, 0.20))
	# Основной осколок
	draw_circle(Vector2.ZERO, r, Color(0.7, 0.95, 1.0, 1.0))
	draw_circle(Vector2.ZERO, r * 0.5, Color(0.9, 1.0, 1.0, 0.95))
	draw_circle(Vector2.ZERO, r * 0.2, Color(1.0, 1.0, 1.0, 1.0))
	# Острые грани
	for i in 4:
		var angle = _angle * 0.3 + i * (TAU / 4.0)
		var sp = Vector2(cos(angle), sin(angle)) * r * 0.8
		draw_circle(sp, r * 0.12, Color(0.8, 0.97, 1.0, 0.85))

# ── Уровень 2: ледяная глыба (замедляет) ─────────────────
func _draw_ice_block(t: float) -> void:
	var r = LEVEL_DATA[2]["radius"]
	var pulse = 1.0 + sin(t * 6.0) * 0.05

	# Внешнее свечение
	draw_circle(Vector2.ZERO, r * pulse * 2.0, Color(0.4, 0.8, 1.0, 0.08))
	draw_circle(Vector2.ZERO, r * pulse * 1.5, Color(0.5, 0.85, 1.0, 0.18))
	draw_circle(Vector2.ZERO, r * pulse * 1.2, Color(0.5, 0.85, 1.0, 0.35))
	# Основная глыба
	draw_circle(Vector2.ZERO, r * pulse, Color(0.5, 0.85, 1.0, 1.0))
	draw_circle(Vector2.ZERO, r * pulse * 0.65, Color(0.7, 0.93, 1.0, 0.9))
	draw_circle(Vector2.ZERO, r * pulse * 0.3, Color(0.9, 1.0, 1.0, 1.0))
	# Кристаллы льда (вращаются)
	for i in 6:
		var angle = _angle * 0.5 + i * (TAU / 6.0)
		var sp = Vector2(cos(angle), sin(angle)) * r * 0.8
		draw_circle(sp, r * 0.15, Color(0.8, 0.96, 1.0, 0.8))
	# Индикатор "замедление" (снежинка)
	for i in 3:
		var angle = i * (TAU / 3.0)
		var sp1 = Vector2(cos(angle), sin(angle)) * r * 0.55
		var sp2 = Vector2(cos(angle + PI), sin(angle + PI)) * r * 0.55
		draw_line(sp1, sp2, Color(1.0, 1.0, 1.0, 0.6), 1.5)

# ── Уровень 3: ледяной шторм (три осколка) ───────────────
func _draw_ice_storm(t: float) -> void:
	var r = LEVEL_DATA[3]["radius"]

	draw_circle(Vector2.ZERO, r * 2.2, Color(0.3, 0.75, 1.0, 0.10))
	draw_circle(Vector2.ZERO, r * 1.6, Color(0.3, 0.75, 1.0, 0.25))
	draw_circle(Vector2.ZERO, r, Color(0.3, 0.75, 1.0, 1.0))
	draw_circle(Vector2.ZERO, r * 0.55, Color(0.6, 0.9, 1.0, 0.95))
	draw_circle(Vector2.ZERO, r * 0.22, Color(1.0, 1.0, 1.0, 1.0))

	# Вращающиеся осколки
	for i in 8:
		var angle = _angle * 2.0 + i * (TAU / 8.0)
		var sp = Vector2(cos(angle), sin(angle)) * r * 1.4
		draw_circle(sp, r * 0.14, Color(0.7, 0.95, 1.0, 0.85))

	# Мигающий контур
	if sin(t * 12.0) > 0.2:
		draw_circle(Vector2.ZERO, r * 1.9, Color(0.5, 0.85, 1.0, 0.12))

# ── Уровень 4: абсолютный ноль (заморозка) ───────────────
func _draw_absolute_zero(t: float) -> void:
	var r = LEVEL_DATA[4]["radius"]

	# Ореол заморозки
	draw_circle(Vector2.ZERO, r * 3.0, Color(0.0, 0.5, 1.0, 0.06))
	draw_circle(Vector2.ZERO, r * 2.2, Color(0.1, 0.6, 1.0, 0.15))
	draw_circle(Vector2.ZERO, r * 1.6, Color(0.1, 0.6, 1.0, 0.30))
	draw_circle(Vector2.ZERO, r, Color(0.1, 0.6, 1.0, 1.0))
	draw_circle(Vector2.ZERO, r * 0.6, Color(0.4, 0.8, 1.0, 0.95))
	# Тёмное ледяное ядро
	draw_circle(Vector2.ZERO, r * 0.25, Color(0.0, 0.15, 0.4, 0.95))

	# Двойное вращение осколков
	for i in 6:
		var angle = _angle * 1.5 + i * (TAU / 6.0)
		var sp = Vector2(cos(angle), sin(angle)) * r * 1.5
		draw_circle(sp, r * 0.18, Color(0.5, 0.85, 1.0, 0.80))
	for i in 4:
		var angle = -_angle * 2.0 + i * (TAU / 4.0)
		var sp = Vector2(cos(angle), sin(angle)) * r * 0.75
		draw_circle(sp, r * 0.12, Color(0.8, 0.96, 1.0, 0.70))

	# Пульсирующий внешний круг
	var pulse_r = r * (2.5 + sin(t * 8.0) * 0.3)
	draw_circle(Vector2.ZERO, pulse_r, Color(0.2, 0.7, 1.0, 0.08))

func _physics_process(delta: float) -> void:
	_lifetime += delta
	_angle    += delta * 3.5

	if _lifetime >= _max_lifetime:
		var tw = create_tween()
		tw.tween_property(self, "modulate:a", 0.0, 0.15)
		tw.tween_callback(queue_free)
		set_physics_process(false)
		return

	if level >= 1:
		_trail.append(global_position)
		if _trail.size() > 8:
			_trail.pop_front()

	position += direction * speed * delta

	var pulse = 1.0 + sin(_lifetime * 10.0) * 0.05
	scale = Vector2(pulse, pulse)
	queue_redraw()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		return

	if body in _hit_bodies:
		return

	if body.has_method("take_damage"):
		body.take_damage(damage)

	# Уровень 2 - замедление
	if level >= 2 and body.has_node("StateMachine"):
		_apply_slow(body)

	# Уровень 4 - полная заморозка
	if level == 4:
		_apply_freeze(body)
		_hit_bodies.append(body)
		return  # пробивает насквозь

	queue_free()

func _apply_slow(body: Node) -> void:
	if not is_instance_valid(body):
		return
	var orig_speed = body.speed
	body.speed *= 0.4
	body.modulate = Color(0.6, 0.85, 1.0)
	print("❄️ Враг замедлен!")
	await get_tree().create_timer(_slow_duration).timeout
	if is_instance_valid(body):
		body.speed = orig_speed
		body.modulate = Color.WHITE
		print("❄️ Замедление снято")

func _apply_freeze(body: Node) -> void:
	if not is_instance_valid(body):
		return
	if body.has_node("StateMachine"):
		body.set_physics_process(false)
		body.modulate = Color(0.5, 0.8, 1.0)
		print("❄️ Враг заморожен!")
		await get_tree().create_timer(3.0).timeout
		if is_instance_valid(body):
			body.set_physics_process(true)
			body.modulate = Color.WHITE
			print("❄️ Заморозка снята")
