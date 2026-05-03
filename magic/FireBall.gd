extends Area2D

var level: int = 1
var damage: float = 10.0
var speed: float = 260.0
var direction: Vector2 = Vector2.RIGHT
var _lifetime: float = 0.0
var _angle: float = 0.0
var _trail: Array = []  # след для уровня 2

const LEVEL_DATA = {
	1: { "radius": 7.0,  "color": Color(1.0, 0.5,  0.0), "speed": 260.0, "damage": 10.0, "max_life": 2.0 },
	2: { "radius": 8.0,  "color": Color(1.0, 0.75, 0.0), "speed": 420.0, "damage": 22.0, "max_life": 1.5 },
	3: { "radius": 14.0, "color": Color(1.0, 0.25, 0.0), "speed": 300.0, "damage": 40.0, "max_life": 2.4 },
	4: { "radius": 10.0, "color": Color(0.8, 0.0,  0.0), "speed": 350.0, "damage": 70.0, "max_life": 2.0 },
}
var _max_lifetime: float = 2.0

# Для уровня 3 - взрыв по области
var _exploded: bool = false
var _explosion_radius: float = 60.0
var _explosion_time: float = 0.0
var _exploding: bool = false

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
	tw.tween_property(self, "scale", Vector2.ONE, 0.10)

func _draw() -> void:
	var data   = LEVEL_DATA[level]
	var r: float    = data["radius"]
	var col: Color  = data["color"]
	var t = _lifetime

	match level:
		1: _draw_level1(r, col, t)
		2: _draw_level2(r, col, t)
		3:
			if _exploding:
				_draw_explosion(t)
			else:
				_draw_level3(r, col, t)
		4: _draw_level4(r, col, t)

# ── Уровень 1: классический огненный шар ─────────────────
func _draw_level1(r: float, col: Color, t: float) -> void:
	draw_circle(Vector2.ZERO, r * 2.2, Color(col.r, col.g, 0.0, 0.10))
	draw_circle(Vector2.ZERO, r * 1.6, Color(col.r, col.g, 0.0, 0.22))
	draw_circle(Vector2.ZERO, r * 1.2, Color(col.r, col.g, 0.0, 0.45))
	draw_circle(Vector2.ZERO, r, col)
	draw_circle(Vector2.ZERO, r * 0.55, Color(1.0, 0.95, 0.4, 0.90))
	draw_circle(Vector2.ZERO, r * 0.25, Color(1.0, 1.0,  0.9, 1.00))
	for i in 4:
		var angle = _angle + i * (TAU / 4.0)
		var sp = Vector2(cos(angle), sin(angle)) * r * 1.2
		draw_circle(sp, r * 0.18, Color(1.0, 0.5, 0.0, 0.60))

# ── Уровень 2: быстрый снаряд с огненным хвостом ─────────
func _draw_level2(r: float, col: Color, t: float) -> void:
	# Хвост из следа
	for i in _trail.size():
		var alpha = float(i) / _trail.size() * 0.5
		var size  = r * (float(i) / _trail.size()) * 0.8
		var local_pos = _trail[i] - global_position
		draw_circle(local_pos, size, Color(1.0, 0.4, 0.0, alpha))

	# Острый снаряд (вытянутый эллипс)
	draw_circle(Vector2.ZERO, r * 1.4, Color(1.0, 0.7, 0.0, 0.25))
	draw_circle(Vector2.ZERO, r, col)
	draw_circle(Vector2.ZERO, r * 0.5, Color(1.0, 1.0, 0.6, 0.95))

	# Искры спереди
	var front = direction * r * 1.3
	draw_circle(front, r * 0.25, Color(1.0, 0.9, 0.2, 0.85))
	draw_circle(front * 1.6, r * 0.15, Color(1.0, 0.7, 0.1, 0.60))

# ── Уровень 3: медленный шар → взрыв по области ──────────
func _draw_level3(r: float, col: Color, t: float) -> void:
	# Пульсирующий шар
	var pulse_r = r + sin(t * 8.0) * 2.0
	draw_circle(Vector2.ZERO, pulse_r * 2.0, Color(1.0, 0.2, 0.0, 0.12))
	draw_circle(Vector2.ZERO, pulse_r * 1.5, Color(1.0, 0.2, 0.0, 0.28))
	draw_circle(Vector2.ZERO, pulse_r, col)
	draw_circle(Vector2.ZERO, pulse_r * 0.6, Color(1.0, 0.8, 0.1, 0.90))
	draw_circle(Vector2.ZERO, pulse_r * 0.25, Color(1.0, 1.0, 0.8, 1.00))

	# Вращающиеся искры
	for i in 6:
		var angle = _angle + i * (TAU / 6.0)
		var sp = Vector2(cos(angle), sin(angle)) * pulse_r * 1.4
		draw_circle(sp, r * 0.16, Color(1.0, 0.8, 0.0, 0.80))

	# Индикатор "готов взорваться" (мигает)
	if sin(t * 15.0) > 0.3:
		draw_circle(Vector2.ZERO, pulse_r * 1.8, Color(1.0, 0.0, 0.0, 0.15))

func _draw_explosion(t: float) -> void:
	# Расширяющееся кольцо взрыва
	var progress = _explosion_time / 0.4
	var exp_r = _explosion_radius * progress
	var alpha = (1.0 - progress)

	draw_circle(Vector2.ZERO, exp_r,        Color(1.0, 0.4, 0.0, alpha * 0.6))
	draw_circle(Vector2.ZERO, exp_r * 0.75, Color(1.0, 0.7, 0.0, alpha * 0.8))
	draw_circle(Vector2.ZERO, exp_r * 0.4,  Color(1.0, 0.95, 0.3, alpha))

	# Лучи взрыва
	for i in 8:
		var angle = i * (TAU / 8.0)
		var sp = Vector2(cos(angle), sin(angle)) * exp_r * 0.9
		draw_circle(sp, 4.0 * alpha, Color(1.0, 0.6, 0.0, alpha))

# ── Уровень 4: три шара - рисуем только основной ─────────
func _draw_level4(r: float, col: Color, t: float) -> void:
	draw_circle(Vector2.ZERO, r * 2.5, Color(0.6, 0.0, 0.0, 0.10))
	draw_circle(Vector2.ZERO, r * 1.8, Color(0.7, 0.0, 0.0, 0.25))
	draw_circle(Vector2.ZERO, r, col)
	draw_circle(Vector2.ZERO, r * 0.55, Color(1.0, 0.3, 0.0, 0.90))
	draw_circle(Vector2.ZERO, r * 0.22, Color(0.1, 0.0, 0.0, 0.95))

	# Тёмные вихри
	for i in 6:
		var angle = _angle * 1.2 + i * (TAU / 6.0)
		var sp = Vector2(cos(angle), sin(angle)) * r * 1.5
		draw_circle(sp, r * 0.20, Color(0.4, 0.0, 0.0, 0.75))
	for i in 4:
		var angle = -_angle + i * (TAU / 4.0)
		var sp = Vector2(cos(angle), sin(angle)) * r * 0.75
		draw_circle(sp, r * 0.12, Color(0.15, 0.0, 0.0, 0.85))

func _physics_process(delta: float) -> void:
	_lifetime += delta
	_angle    += delta * 4.0

	# Взрыв по области (уровень 3)
	if _exploding:
		_explosion_time += delta
		queue_redraw()
		if _explosion_time >= 0.4:
			queue_free()
		return

	if _lifetime >= _max_lifetime:
		if level == 3 and not _exploded:
			_do_explosion()
			return
		var tw = create_tween()
		tw.tween_property(self, "modulate:a", 0.0, 0.15)
		tw.tween_callback(queue_free)
		set_physics_process(false)
		return

	# Хвост для уровня 2
	if level == 2:
		_trail.append(global_position)
		if _trail.size() > 8:
			_trail.pop_front()

	position += direction * speed * delta

	var pulse = 1.0 + sin(_lifetime * 14.0) * 0.08
	scale = Vector2(pulse, pulse)
	queue_redraw()

func _do_explosion() -> void:
	_exploded  = true
	_exploding = true
	_explosion_time = 0.0
	speed = 0.0

	# Урон по области
	var space = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var shape = CircleShape2D.new()
	shape.radius = _explosion_radius
	query.shape = shape
	query.transform = Transform2D(0, global_position)
	query.collision_mask = 0b00000110
	var results = space.intersect_shape(query)
	for result in results:
		var body = result["collider"]
		if body.has_method("take_damage") and not body.is_in_group("player"):
			body.take_damage(damage)
			print("💥 Взрыв нанёс урон:", body.name)

	queue_redraw()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		return
	if body.has_method("take_damage"):
		body.take_damage(damage)

	# Уровень 3 — взрыв вместо исчезновения
	if level == 3 and not _exploded:
		_do_explosion()
	else:
		queue_free()
