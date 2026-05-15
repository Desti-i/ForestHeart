extends Area2D

var level: int = 1
var damage: float = 10.0
var speed: float = 260.0
var direction: Vector2 = Vector2.RIGHT
var _lifetime: float = 0.0
var _angle: float = 0.0
var _trail: Array = []  # след для уровня 2

func _draw_explosion(t: float) -> void:
	var progress = _explosion_time / 0.4

	var radius = lerp(10.0, _explosion_radius, progress)
	var alpha = 1.0 - progress

	# Основной взрыв
	draw_circle(
		Vector2.ZERO,
		radius,
		Color(1.0, 0.4, 0.0, alpha)
	)

	# Внутреннее ядро
	draw_circle(
		Vector2.ZERO,
		radius * 0.5,
		Color(1.0, 0.8, 0.2, alpha)
	)

	# Внешняя волна
	draw_circle(
		Vector2.ZERO,
		radius * 1.2,
		Color(1.0, 0.2, 0.0, alpha * 0.4)
	)

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

# ─────────────────────────────────────────────
# УРОВЕНЬ 1 — ЖИВОЙ ОГНЕННЫЙ ШАР
# ─────────────────────────────────────────────
func _draw_level1(r: float, col: Color, t: float) -> void:

	# Внешний glow
	draw_circle(Vector2.ZERO, r * 3.0, Color(1.0, 0.35, 0.0, 0.05))
	draw_circle(Vector2.ZERO, r * 2.1, Color(1.0, 0.45, 0.0, 0.15))
	draw_circle(Vector2.ZERO, r * 1.6, Color(1.0, 0.55, 0.0, 0.30))

	# Огненная оболочка
	var flame = PackedVector2Array()

	for i in 18:
		var angle = i * TAU / 18.0

		var wave = sin(t * 8.0 + i) * r * 0.25

		var dist = r * 1.2 + wave

		flame.append(
			Vector2(cos(angle), sin(angle)) * dist
		)

	draw_colored_polygon(
		flame,
		Color(1.0, 0.35, 0.0, 0.95)
	)

	# Внутреннее ядро
	draw_circle(
		Vector2.ZERO,
		r * 0.8,
		Color(1.0, 0.75, 0.15, 0.95)
	)

	draw_circle(
		Vector2.ZERO,
		r * 0.4,
		Color(1.0, 1.0, 0.85, 1.0)
	)

	# Искры
	for i in 6:
		var angle = -_angle * 2.0 + i * TAU / 6.0

		var dist = r * 1.8

		var pos = Vector2(
			cos(angle),
			sin(angle)
		) * dist

		draw_circle(
			pos,
			r * 0.10,
			Color(1.0, 0.8, 0.2, 0.7)
		)


# ─────────────────────────────────────────────
# УРОВЕНЬ 2 — ОГНЕННОЕ КОПЬЁ
# ─────────────────────────────────────────────
func _draw_level2(r: float, col: Color, t: float) -> void:

	# Хвост
	for i in _trail.size():

		var k = float(i) / _trail.size()

		var alpha = k * 0.45
		var size = r * k * 1.2

		var lp = _trail[i] - global_position

		draw_circle(
			lp,
			size,
			Color(1.0, 0.3, 0.0, alpha)
		)

	# Внешний огонь
	draw_circle(Vector2.ZERO, r * 2.6, Color(1.0, 0.4, 0.0, 0.08))
	draw_circle(Vector2.ZERO, r * 1.8, Color(1.0, 0.55, 0.0, 0.20))

	# Огненное копьё
	var spear = PackedVector2Array()

	spear.append(Vector2(r * 2.2, 0))
	spear.append(Vector2(-r * 1.3, -r * 0.9))
	spear.append(Vector2(-r * 0.7, 0))
	spear.append(Vector2(-r * 1.3, r * 0.9))

	draw_colored_polygon(
		spear,
		Color(1.0, 0.5, 0.0, 0.95)
	)

	# Ядро
	draw_circle(
		Vector2.ZERO,
		r * 0.45,
		Color(1.0, 1.0, 0.7, 0.95)
	)

	# Передняя энергия
	var front = direction * r * 2.0

	draw_circle(
		front,
		r * 0.25,
		Color(1.0, 0.9, 0.3, 0.85)
	)


# ─────────────────────────────────────────────
# УРОВЕНЬ 3 — ОГНЕННОЕ СОЛНЕЧНОЕ КОЛЬЦО
# вокруг игрока вращается магический круг
# который наносит урон по области
# ─────────────────────────────────────────────

func _draw_level3(r: float, col: Color, t: float) -> void:

	# ── ВНЕШНЕЕ СВЕЧЕНИЕ ──────────────────
	draw_circle(
		Vector2.ZERO,
		r * 5.0,
		Color(1.0, 0.2, 0.0, 0.04)
	)

	draw_circle(
		Vector2.ZERO,
		r * 3.5,
		Color(1.0, 0.3, 0.0, 0.10)
	)

	# ──────────────────────────────────────
	# ВРАЩАЮЩЕЕСЯ КОЛЬЦО
	# ──────────────────────────────────────

	var ring_radius = r * 2.6

	for i in 18:

		var angle = _angle * 1.8 + i * TAU / 18.0

		var pos = Vector2(
			cos(angle),
			sin(angle)
		) * ring_radius

		# огненные руны
		draw_circle(
			pos,
			r * 0.20,
			Color(1.0, 0.45, 0.0, 0.85)
		)

	# ──────────────────────────────────────
	# ВНЕШНЕЕ ОГНЕННОЕ КОЛЬЦО
	# ──────────────────────────────────────

	for i in 42:

		var angle = i * TAU / 42.0

		var wave = sin(t * 8.0 + i) * 3.0

		var dist = ring_radius + wave

		var pos = Vector2(
			cos(angle),
			sin(angle)
		) * dist

		draw_circle(
			pos,
			r * 0.08,
			Color(1.0, 0.25, 0.0, 0.55)
		)

	# ──────────────────────────────────────
	# ЦЕНТРАЛЬНОЕ ЯДРО
	# ──────────────────────────────────────

	draw_circle(
		Vector2.ZERO,
		r * 1.5,
		Color(1.0, 0.25, 0.0, 0.92)
	)

	draw_circle(
		Vector2.ZERO,
		r * 0.95,
		Color(1.0, 0.75, 0.15, 0.95)
	)

	draw_circle(
		Vector2.ZERO,
		r * 0.40,
		Color(1.0, 1.0, 0.85, 1.0)
	)

	# ──────────────────────────────────────
	# ОГНЕННЫЕ ЛУЧИ
	# ──────────────────────────────────────

	for i in 8:

		var angle = -_angle * 1.2 + i * TAU / 8.0

		var dir = Vector2(
			cos(angle),
			sin(angle)
		)

		draw_line(
			dir * r * 0.8,
			dir * r * 2.4,
			Color(1.0, 0.5, 0.0, 0.35),
			2.0
		)

	# ──────────────────────────────────────
	# ЛЕТАЮЩИЕ УГЛИ
	# ──────────────────────────────────────

	for i in 14:

		var angle = _angle * 2.4 + i * TAU / 14.0

		var dist = r * (3.0 + sin(t * 4.0 + i) * 0.4)

		var pos = Vector2(
			cos(angle),
			sin(angle)
		) * dist

		draw_circle(
			pos,
			r * 0.12,
			Color(1.0, 0.7, 0.1, 0.75)
		)

	# ──────────────────────────────────────
	# ПУЛЬС ПЕРЕГРУЗКИ
	# ──────────────────────────────────────

	if sin(t * 14.0) > 0.35:

		draw_circle(
			Vector2.ZERO,
			r * 3.4,
			Color(1.0, 0.0, 0.0, 0.06)
		)
# ─────────────────────────────────────────────
# УРОВЕНЬ 4 — ТЁМНОЕ ПЛАМЯ
# ─────────────────────────────────────────────
func _draw_level4(r: float, col: Color, t: float) -> void:

	draw_circle(Vector2.ZERO, r * 3.2, Color(0.5, 0.0, 0.0, 0.05))
	draw_circle(Vector2.ZERO, r * 2.0, Color(0.7, 0.0, 0.0, 0.15))

	# Внешнее пламя
	var flame = PackedVector2Array()

	for i in 16:

		var angle = i * TAU / 16.0

		var wave = sin(t * 12.0 + i) * r * 0.35

		var dist = r * 1.4 + wave

		flame.append(
			Vector2(cos(angle), sin(angle)) * dist
		)

	draw_colored_polygon(
		flame,
		Color(0.75, 0.0, 0.0, 0.95)
	)

	# Тёмное ядро
	draw_circle(
		Vector2.ZERO,
		r * 0.75,
		Color(0.2, 0.0, 0.0, 1.0)
	)

	draw_circle(
		Vector2.ZERO,
		r * 0.28,
		Color(1.0, 0.25, 0.0, 0.9)
	)

	# Тёмные угли
	for i in 8:

		var angle = -_angle * 1.5 + i * TAU / 8.0

		var dist = r * 2.0

		var pos = Vector2(
			cos(angle),
			sin(angle)
		) * dist

		draw_circle(
			pos,
			r * 0.13,
			Color(0.4, 0.0, 0.0, 0.7)
		)

func _physics_process(delta: float) -> void:
	rotation += delta * 2.5
	_lifetime += delta
	_angle    += delta * 6.5

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
			body.take_damage(damage, "fire")
			print("💥 Взрыв нанёс урон:", body.name)

	queue_redraw()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		return
	if body.has_method("take_damage"):
		body.take_damage(damage, "fire")

	# Уровень 3 — взрыв вместо исчезновения
	if level == 3 and not _exploded:
		_do_explosion()
	else:
		queue_free()
