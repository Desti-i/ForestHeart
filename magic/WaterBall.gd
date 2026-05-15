extends Area2D

var level: int = 1
var damage: float = 15.0
var speed: float = 240.0
var direction: Vector2 = Vector2.RIGHT
var _lifetime: float = 0.0
var _angle: float = 0.0
var _trail: Array = []
var _hit_bodies: Array = []  # для уровня 4 - пробивание

const LEVEL_DATA = {
	1: { "radius": 8.0,  "speed": 240.0, "damage": 15.0, "max_life": 2.0 },
	2: { "radius": 9.0,  "speed": 380.0, "damage": 30.0, "max_life": 1.8 },
	3: { "radius": 22.0, "speed": 200.0, "damage": 55.0, "max_life": 1.6 },
	4: { "radius": 6.0,  "speed": 500.0, "damage": 90.0, "max_life": 1.5 },
}
var _max_lifetime: float = 2.0

# Для уровня 3 - взрыв волны
var _exploded: bool = false
var _exploding: bool = false
var _explosion_time: float = 0.0
var _wave_radius: float = 80.0

func setup(lvl: int, dir: Vector2) -> void:
	level     = lvl
	direction = dir.normalized()
	var data  = LEVEL_DATA[lvl]
	speed     = data["speed"]
	damage    = data["damage"]
	_max_lifetime = data["max_life"]

func _ready() -> void:
	collision_layer = 0
	collision_mask  = 0xFFFFFFFF
	monitoring = true
	body_entered.connect(_on_body_entered)

	var shape = CircleShape2D.new()
	# Уровень 3 - широкая волна
	if level == 3:
		var capsule = CapsuleShape2D.new()
		capsule.radius = 12.0
		capsule.height = 40.0
		shape.radius = 18.0
		var col = CollisionShape2D.new()
		col.shape = shape
		col.rotation = direction.angle() + PI / 2.0
		add_child(col)
	else:
		shape.radius = LEVEL_DATA[level]["radius"]
		var col = CollisionShape2D.new()
		col.shape = shape
		add_child(col)

	rotation = direction.angle()

	scale = Vector2.ZERO
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector2.ONE, 0.10)

func _draw() -> void:
	var t = _lifetime
	match level:
		1: _draw_water_orb(t)
		2: _draw_ice_bolt(t)
		3:
			if _exploding:
				_draw_wave_explosion(t)
			else:
				_draw_tsunami(t)
		4: _draw_water_beam(t)

# ── Уровень 1: водяной шар ────────────────────────────────
func _draw_water_orb(t: float) -> void:
	var r = LEVEL_DATA[1]["radius"]
	var col = Color(0.2, 0.7, 1.0)

	draw_circle(Vector2.ZERO, r * 2.8, Color(0.3, 0.8, 1.0, 0.07 + sin(t*8)*0.03))
	draw_circle(Vector2.ZERO, r * 2.0, Color(0.1, 0.6, 1.0, 0.15))
	draw_circle(Vector2.ZERO, r * 1.4, Color(0.0, 0.5, 1.0, 0.30))
	draw_circle(Vector2.ZERO, r, col)
	draw_circle(Vector2.ZERO, r * 0.65, Color(0.5, 0.85, 1.0, 0.85))
	# Блик
	draw_circle(Vector2(-r*0.3, -r*0.3), r * 0.22, Color(0.9, 0.97, 1.0, 0.90))
	draw_circle(Vector2(-r*0.2, -r*0.2), r * 0.10, Color(1.0, 1.0, 1.0, 1.00))
	# Капли вокруг
	for i in 5:
		var angle = _angle + i * (TAU / 5.0)
		var sp = Vector2(cos(angle), sin(angle)) * r * 1.3
		draw_circle(sp, r * (0.13 + sin(t*6+i)*0.04), Color(0.4, 0.85, 1.0, 0.75))

# ── Уровень 2: ледяной снаряд с хвостом ──────────────────
func _draw_ice_bolt(t: float) -> void:
	var r = LEVEL_DATA[2]["radius"]

	# Хвост
	for i in _trail.size():
		var alpha = float(i) / _trail.size() * 0.45
		var size  = r * (float(i) / _trail.size()) * 0.7
		var lp    = _trail[i] - global_position
		draw_circle(lp, size, Color(0.5, 0.9, 1.0, alpha))

	# Острый ледяной снаряд
	draw_circle(Vector2.ZERO, r * 1.6, Color(0.4, 0.85, 1.0, 0.20))
	draw_circle(Vector2.ZERO, r, Color(0.2, 0.6, 1.0, 1.0))
	draw_circle(Vector2.ZERO, r * 0.55, Color(0.7, 0.95, 1.0, 0.95))
	draw_circle(Vector2.ZERO, r * 0.20, Color(1.0, 1.0, 1.0, 1.00))

	# Ледяные грани (снежинка)
	for i in 6:
		var angle = _angle * 0.5 + i * (TAU / 6.0)
		var sp = Vector2(cos(angle), sin(angle)) * r * 0.75
		draw_circle(sp, r * 0.10, Color(0.85, 0.98, 1.0, 0.80))

	# Искры впереди
	var front = direction * r * 1.4
	draw_circle(front,       r * 0.22, Color(0.8, 0.95, 1.0, 0.85))
	draw_circle(front * 1.7, r * 0.13, Color(0.6, 0.90, 1.0, 0.60))

# ── Уровень 3: волна цунами ───────────────────────────────
func _draw_tsunami(t: float) -> void:
	# Широкая волна перпендикулярно направлению
	var perp = Vector2(-direction.y, direction.x)  # перпендикуляр
	var wave_w = 40.0  # полуширина волны
	var wave_h = 18.0  # высота волны
	var pulse  = sin(t * 6.0) * 2.0

	# Основное тело волны
	for i in 7:
		var offset = (float(i) / 6.0 - 0.5) * wave_w * 2.0
		var sp     = perp * offset
		var height = wave_h - abs(offset) / wave_w * 8.0 + pulse
		draw_circle(sp, height, Color(0.0, 0.4, 0.9, 0.85 - abs(offset)/wave_w * 0.4))

	# Пена сверху
	for i in 9:
		var offset = (float(i) / 8.0 - 0.5) * wave_w * 2.2
		var sp     = perp * offset + direction * (6.0 + sin(t*8+i)*2.0)
		draw_circle(sp, 4.5 + sin(t*10+i)*1.5, Color(0.7, 0.92, 1.0, 0.80))

	# Брызги
	for i in 6:
		var angle  = _angle * 2.0 + i * (TAU / 6.0)
		var sp     = perp * (cos(angle) * wave_w * 0.9) + direction * (sin(angle) * 8.0)
		draw_circle(sp, 3.0 + sin(t*12+i)*1.0, Color(0.5, 0.85, 1.0, 0.70))

	# Свечение воды
	draw_circle(Vector2.ZERO, wave_h * 1.8, Color(0.0, 0.5, 1.0, 0.10))

func _draw_wave_explosion(t: float) -> void:
	var progress = _explosion_time / 0.5
	var exp_r    = _wave_radius * progress
	var alpha    = 1.0 - progress

	# Расширяющаяся волна
	draw_circle(Vector2.ZERO, exp_r,        Color(0.0, 0.4, 0.9, alpha * 0.5))
	draw_circle(Vector2.ZERO, exp_r * 0.75, Color(0.2, 0.6, 1.0, alpha * 0.7))
	draw_circle(Vector2.ZERO, exp_r * 0.45, Color(0.5, 0.85, 1.0, alpha * 0.9))

	# Брызги по кругу
	for i in 10:
		var angle = i * (TAU / 10.0)
		var sp    = Vector2(cos(angle), sin(angle)) * exp_r * 0.85
		draw_circle(sp, 5.0 * alpha, Color(0.6, 0.9, 1.0, alpha))

	# Пена в центре
	draw_circle(Vector2.ZERO, exp_r * 0.2, Color(0.8, 0.95, 1.0, alpha))

# ── Уровень 4: водяной луч ────────────────────────────────
func _draw_water_beam(t: float) -> void:
	var r = LEVEL_DATA[4]["radius"]

	# Хвост луча
	for i in _trail.size():
		var alpha = float(i) / _trail.size() * 0.6
		var w     = r * 1.5 * (float(i) / _trail.size())
		var lp    = _trail[i] - global_position
		draw_circle(lp, w, Color(0.0, 0.5, 1.0, alpha))

	# Внешнее свечение
	draw_circle(Vector2.ZERO, r * 3.0, Color(0.0, 0.6, 1.0, 0.08))
	draw_circle(Vector2.ZERO, r * 2.0, Color(0.0, 0.5, 1.0, 0.20))

	# Ядро луча (яркое)
	draw_circle(Vector2.ZERO, r * 1.2, Color(0.2, 0.7, 1.0, 1.0))
	draw_circle(Vector2.ZERO, r * 0.7, Color(0.6, 0.92, 1.0, 1.0))
	draw_circle(Vector2.ZERO, r * 0.3, Color(0.95, 1.0,  1.0, 1.0))

	# Спираль вокруг луча
	for i in 6:
		var angle = _angle * 3.0 + i * (TAU / 6.0)
		var dist  = r * 1.5
		var sp    = Vector2(cos(angle), sin(angle)) * dist
		draw_circle(sp, r * 0.20, Color(0.3, 0.8, 1.0, 0.65))

	# Конус впереди
	var front = direction * r * 2.0
	draw_circle(front,       r * 0.45, Color(0.5, 0.9, 1.0, 0.85))
	draw_circle(front * 1.5, r * 0.28, Color(0.7, 0.95, 1.0, 0.65))
	draw_circle(front * 2.2, r * 0.14, Color(0.9, 1.0,  1.0, 0.45))

func _physics_process(delta: float) -> void:
	_lifetime += delta
	_angle    += delta * 3.0

	# Взрыв волны (уровень 3)
	if _exploding:
		_explosion_time += delta
		queue_redraw()
		if _explosion_time >= 0.5:
			queue_free()
		return

	if _lifetime >= _max_lifetime:
		if level == 3 and not _exploded:
			_do_wave_explosion()
			return
		var tw = create_tween()
		tw.tween_property(self, "modulate:a", 0.0, 0.15)
		tw.tween_callback(queue_free)
		set_physics_process(false)
		return

	# Хвост для уровня 2 и 4
	if level == 2 or level == 4:
		_trail.append(global_position)
		if _trail.size() > 10:
			_trail.pop_front()

	position += direction * speed * delta

	# Уровень 3 - чуть покачивается
	if level == 3:
		var wobble = Vector2(-direction.y, direction.x) * sin(_lifetime * 5.0) * 0.5
		position += wobble

	var pulse = 1.0 + sin(_lifetime * 10.0) * 0.05
	scale = Vector2(pulse, pulse)
	queue_redraw()

func _do_wave_explosion() -> void:
	_exploded  = true
	_exploding = true
	_explosion_time = 0.0
	speed = 0.0

	# Урон по области
	var space = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var shape = CircleShape2D.new()
	shape.radius = _wave_radius
	query.shape = shape
	query.transform = Transform2D(0, global_position)
	query.collision_mask = 0xFFFFFFFF
	var results = space.intersect_shape(query)
	for result in results:
		var body = result["collider"]
		if body.has_method("take_damage") and not body.is_in_group("player"):
			body.take_damage(damage, "water")
			print("🌊 Волна нанесла урон:", body.name)
	queue_redraw()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		return

	# Уровень 4 - пробивание (бьёт несколько врагов)
	if level == 4:
		if body in _hit_bodies:
			return
		_hit_bodies.append(body)
		if body.has_method("take_damage"):
			body.take_damage(damage, "water")
		return

	# Уровень 3 - взрыв волны
	if level == 3 and not _exploded:
		if body.has_method("take_damage"):
			body.take_damage(damage, "water")
		_do_wave_explosion()
		return

	if body.has_method("take_damage"):
		body.take_damage(damage, "water")
	queue_free()
