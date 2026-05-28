extends Area2D

var level: int = 1
var damage: float = 18.0
var speed: float = 350.0
var direction: Vector2 = Vector2.RIGHT
var _lifetime: float = 0.0
var _angle: float = 0.0
var _trail: Array = []
var _hit_bodies: Array = [] 

const LEVEL_DATA = {
	1: { "radius": 6.0,  "speed": 350.0, "damage": 18.0,  "max_life": 1.8 },
	2: { "radius": 12.0, "speed": 280.0, "damage": 35.0,  "max_life": 2.2 },
	3: { "radius": 9.0,  "speed": 320.0, "damage": 60.0,  "max_life": 2.0 },
	4: { "radius": 16.0, "speed": 260.0, "damage": 95.0,  "max_life": 2.5 },
}
var _max_lifetime: float = 1.8
var _slow_duration: float = 2.0  

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

# ── Уровень 1
func _draw_ice_shard(t: float) -> void:
	var r = LEVEL_DATA[1]["radius"]

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

# ── Уровень 2
func _draw_ice_block(t: float) -> void:
	var r = LEVEL_DATA[2]["radius"]

	draw_circle(Vector2.ZERO, r * 2.5, Color(0.5, 0.9, 1.0, 0.08))
	draw_circle(Vector2.ZERO, r * 1.8, Color(0.5, 0.85, 1.0, 0.18))

	var poly = PackedVector2Array()

	for i in 8:
		var angle = rotation * 0.5 + i * TAU / 8.0

		var dist = r

		if i % 2 == 0:
			dist *= 1.4

		poly.append(
			Vector2(cos(angle), sin(angle)) * dist
		)

	draw_colored_polygon(
		poly,
		Color(0.6, 0.92, 1.0, 0.95)
	)

	draw_circle(
		Vector2.ZERO,
		r * 0.45,
		Color(0.95, 1.0, 1.0, 0.95)
	)

	for i in 6:
		var angle = _angle + i * TAU / 6.0

		var pos = Vector2(
			cos(angle),
			sin(angle)
		) * r * 1.5

		draw_circle(
			pos,
			r * 0.12,
			Color(0.8, 1.0, 1.0, 0.7)
		)

# ── Уровень 3
func _draw_ice_storm(t: float) -> void:
	var r = LEVEL_DATA[3]["radius"]

	draw_circle(Vector2.ZERO, r * 3.0, Color(0.3, 0.75, 1.0, 0.08))
	draw_circle(Vector2.ZERO, r * 2.0, Color(0.3, 0.8, 1.0, 0.16))

	for i in 12:
		var angle = _angle * 2.0 + i * TAU / 12.0

		var dist = r * (1.2 + sin(t * 4.0 + i) * 0.4)

		var pos = Vector2(
			cos(angle),
			sin(angle)
		) * dist

		var shard = PackedVector2Array()

		for j in 4:
			var a = angle + j * TAU / 4.0

			var d = r * 0.35

			if j % 2 == 0:
				d *= 1.8

			shard.append(
				pos + Vector2(cos(a), sin(a)) * d
			)

		draw_colored_polygon(
			shard,
			Color(0.7, 0.95, 1.0, 0.85)
		)

	draw_circle(
		Vector2.ZERO,
		r * 0.5,
		Color(1.0, 1.0, 1.0, 0.9)
	)

# ── Уровень 4
func _draw_absolute_zero(t: float) -> void:
	var r = LEVEL_DATA[4]["radius"]

	draw_circle(Vector2.ZERO, r * 4.0, Color(0.1, 0.6, 1.0, 0.04))
	draw_circle(Vector2.ZERO, r * 2.8, Color(0.1, 0.6, 1.0, 0.10))
	draw_circle(Vector2.ZERO, r * 1.8, Color(0.2, 0.75, 1.0, 0.25))

	var crystal = PackedVector2Array()

	for i in 10:
		var angle = rotation + i * TAU / 10.0

		var dist = r

		if i % 2 == 0:
			dist *= 2.0

		crystal.append(
			Vector2(cos(angle), sin(angle)) * dist
		)

	draw_colored_polygon(
		crystal,
		Color(0.5, 0.9, 1.0, 0.95)
	)

	draw_circle(
		Vector2.ZERO,
		r * 0.55,
		Color(0.95, 1.0, 1.0, 1.0)
	)

	for i in 14:
		var angle = -_angle * 1.5 + i * TAU / 14.0

		var dist = r * 2.5

		var pos = Vector2(
			cos(angle),
			sin(angle)
		) * dist

		draw_circle(
			pos,
			r * 0.10,
			Color(0.9, 1.0, 1.0, 0.65)
		)
func _physics_process(delta: float) -> void:
	rotation += delta * 4.0
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
		body.take_damage(damage, "ice")

	if level >= 2 and body.has_node("StateMachine"):
		_apply_slow(body)

	if level == 4:
		_apply_freeze(body)
		_hit_bodies.append(body)
		return  

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
