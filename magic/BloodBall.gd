extends Area2D

var level: int = 1
var damage: float = 18.0
var speed: float = 260.0
var direction: Vector2 = Vector2.RIGHT

var _lifetime: float = 0.0
var _angle: float = 0.0
var _trail: Array = []
var _hit_bodies: Array = []

const LEVEL_DATA = {
	1: { "radius": 8.0,  "speed": 260.0, "damage": 18.0,  "max_life": 2.0 },
	2: { "radius": 10.0, "speed": 380.0, "damage": 34.0,  "max_life": 1.7 },
	3: { "radius": 20.0, "speed": 0.0,   "damage": 55.0,  "max_life": 3.0 },
	4: { "radius": 12.0, "speed": 520.0, "damage": 100.0, "max_life": 1.3 },
}

var _max_lifetime: float = 2.0

# уровень 3
var _ring_radius: float = 90.0

func setup(lvl: int, dir: Vector2) -> void:

	level = lvl
	direction = dir.normalized()

	var data = LEVEL_DATA[lvl]

	speed = data["speed"]
	damage = data["damage"]
	_max_lifetime = data["max_life"]


func _ready() -> void:

	collision_layer = 0
	collision_mask = 0xFFFFFFFF

	monitoring = true

	body_entered.connect(_on_body_entered)

	var shape = CircleShape2D.new()

	shape.radius = LEVEL_DATA[level]["radius"]

	var col = CollisionShape2D.new()

	col.shape = shape

	add_child(col)

	scale = Vector2.ZERO

	var tw = create_tween()

	tw.tween_property(
		self,
		"scale",
		Vector2.ONE,
		0.08
	)


func _draw() -> void:

	var t = _lifetime

	match level:

		1:
			_draw_blood_orb(t)

		2:
			_draw_blood_spear(t)

		3:
			_draw_blood_ring(t)

		4:
			_draw_blood_beam(t)



# LEVEL 1 — BLOOD 

func _draw_blood_orb(t: float) -> void:

	var r = LEVEL_DATA[1]["radius"]

	draw_circle(
		Vector2.ZERO,
		r * 3.0,
		Color(0.5, 0.0, 0.0, 0.05)
	)

	draw_circle(
		Vector2.ZERO,
		r * 2.0,
		Color(0.7, 0.0, 0.0, 0.14)
	)

	# живое ядро
	var poly = PackedVector2Array()

	for i in 18:

		var angle = i * TAU / 18.0

		var wave = sin(t * 7.0 + i) * r * 0.18

		var dist = r * 1.2 + wave

		poly.append(
			Vector2(cos(angle), sin(angle)) * dist
		)

	draw_colored_polygon(
		poly,
		Color(0.8, 0.0, 0.0, 0.95)
	)

	draw_circle(
		Vector2.ZERO,
		r * 0.6,
		Color(1.0, 0.2, 0.2, 0.9)
	)

	draw_circle(
		Vector2.ZERO,
		r * 0.2,
		Color(1.0, 0.8, 0.8, 1.0)
	)

	# капли
	for i in 5:

		var angle = _angle * 1.6 + i * TAU / 5.0

		var pos = Vector2(
			cos(angle),
			sin(angle)
		) * r * 1.8

		draw_circle(
			pos,
			r * 0.14,
			Color(0.9, 0.0, 0.0, 0.75)
		)



# LEVEL 2 — BLOOD 

func _draw_blood_spear(t: float) -> void:

	var r = LEVEL_DATA[2]["radius"]

	# хвост
	for i in _trail.size():

		var k = float(i) / _trail.size()

		var lp = _trail[i] - global_position

		draw_circle(
			lp,
			r * k * 1.3,
			Color(0.6, 0.0, 0.0, k * 0.4)
		)

	var spear = PackedVector2Array()

	spear.append(Vector2(r * 3.0, 0))
	spear.append(Vector2(-r * 1.6, -r))
	spear.append(Vector2(-r * 0.4, 0))
	spear.append(Vector2(-r * 1.6, r))

	draw_colored_polygon(
		spear,
		Color(0.9, 0.0, 0.0, 0.96)
	)

	draw_circle(
		Vector2(r * 0.3, 0),
		r * 0.3,
		Color(1.0, 0.5, 0.5, 1.0)
	)

	# тёмные частицы
	for i in 8:

		var angle = -_angle * 2.0 + i * TAU / 8.0

		var pos = Vector2(
			cos(angle),
			sin(angle)
		) * r * 1.7

		draw_circle(
			pos,
			r * 0.10,
			Color(0.2, 0.0, 0.0, 0.8)
		)



# LEVEL 3 — BLOOD 

func _draw_blood_ring(t: float) -> void:

	var r = LEVEL_DATA[3]["radius"]

	draw_circle(
		Vector2.ZERO,
		r * 1.5,
		Color(0.8, 0.0, 0.0, 0.9)
	)

	draw_circle(
		Vector2.ZERO,
		r * 0.7,
		Color(1.0, 0.25, 0.25, 1.0)
	)

	for i in 30:

		var angle = _angle + i * TAU / 30.0

		var pos = Vector2(
			cos(angle),
			sin(angle)
		) * _ring_radius

		draw_circle(
			pos,
			r * 0.15,
			Color(0.7, 0.0, 0.0, 0.75)
		)

	for i in 16:

		var angle = -_angle * 1.5 + i * TAU / 16.0

		var pos = Vector2(
			cos(angle),
			sin(angle)
		) * (_ring_radius * 0.6)

		draw_circle(
			pos,
			r * 0.12,
			Color(1.0, 0.1, 0.1, 0.8)
		)

	# кровавые лучи
	for i in 8:

		var angle = i * TAU / 8.0

		var dir = Vector2(
			cos(angle),
			sin(angle)
		)

		draw_line(
			dir * r,
			dir * _ring_radius,
			Color(0.6, 0.0, 0.0, 0.25),
			2.0
		)

	if sin(t * 10.0) > 0.3:

		draw_circle(
			Vector2.ZERO,
			_ring_radius * 1.05,
			Color(1.0, 0.0, 0.0, 0.04)
		)



# LEVEL 4 — BLOOD

func _draw_blood_beam(t: float) -> void:

	var r = LEVEL_DATA[4]["radius"]

	# хвост
	for i in _trail.size():

		var k = float(i) / _trail.size()

		var lp = _trail[i] - global_position

		draw_circle(
			lp,
			r * k * 1.7,
			Color(0.5, 0.0, 0.0, k * 0.45)
		)

	draw_circle(
		Vector2.ZERO,
		r * 3.5,
		Color(0.4, 0.0, 0.0, 0.06)
	)

	draw_circle(
		Vector2.ZERO,
		r * 2.0,
		Color(0.7, 0.0, 0.0, 0.15)
	)

	# ядро луча
	draw_circle(
		Vector2.ZERO,
		r,
		Color(0.9, 0.0, 0.0, 1.0)
	)

	draw_circle(
		Vector2.ZERO,
		r * 0.5,
		Color(1.0, 0.3, 0.3, 1.0)
	)

	# чёрные частицы
	for i in 10:

		var angle = _angle * 2.5 + i * TAU / 10.0

		var pos = Vector2(
			cos(angle),
			sin(angle)
		) * r * 1.8

		draw_circle(
			pos,
			r * 0.12,
			Color(0.1, 0.0, 0.0, 0.75)
		)

	var front = direction * r * 2.2

	draw_circle(
		front,
		r * 0.35,
		Color(1.0, 0.5, 0.5, 0.9)
	)



func _physics_process(delta: float) -> void:

	_lifetime += delta
	_angle += delta * 4.0

	if _lifetime >= _max_lifetime:

		var tw = create_tween()

		tw.tween_property(
			self,
			"modulate:a",
			0.0,
			0.15
		)

		tw.tween_callback(queue_free)

		set_physics_process(false)

		return

	# хвост
	if level == 2 or level == 4:

		_trail.append(global_position)

		if _trail.size() > 10:
			_trail.pop_front()

	if level != 3:
		position += direction * speed * delta

	var pulse = 1.0 + sin(_lifetime * 8.0) * 0.05

	scale = Vector2.ONE * pulse

	queue_redraw()



func _on_body_entered(body: Node) -> void:

	if body.is_in_group("player"):
		return

	if level == 4:

		if body in _hit_bodies:
			return

		_hit_bodies.append(body)

	if body.has_method("take_damage"):

		body.take_damage(
			damage,
			"blood"
		)

	if level != 4:
		queue_free()
