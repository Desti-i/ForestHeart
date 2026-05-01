extends Area2D

var level: int = 1
var damage: float = 10.0
var speed: float = 260.0
var direction: Vector2 = Vector2.RIGHT
var _lifetime: float = 0.0

const LEVEL_DATA = {
	1: { "radius": 7.0,  "color": Color(1.0, 0.5,  0.0), "speed": 260.0, "damage": 10.0, "max_life": 2.0 },
	2: { "radius": 11.0, "color": Color(1.0, 0.75, 0.0), "speed": 320.0, "damage": 22.0, "max_life": 2.2 },
	3: { "radius": 16.0, "color": Color(1.0, 0.25, 0.0), "speed": 380.0, "damage": 40.0, "max_life": 2.4 },
	4: { "radius": 22.0, "color": Color(0.8, 0.0,  0.0), "speed": 440.0, "damage": 70.0, "max_life": 2.6 },
}

var _max_lifetime: float = 2.0

func setup(lvl: int, dir: Vector2) -> void:
	level = lvl
	direction = dir.normalized()
	var data = LEVEL_DATA[lvl]
	speed = data["speed"]
	damage = data["damage"]
	_max_lifetime = data["max_life"]

func _ready() -> void:
	# ВАЖНО: слои коллизии
	collision_layer = 0   # шар сам не занимает слой
	collision_mask = 0b00000110  # видит слои 2 и 3 (враги)
	monitoring = true
	
	body_entered.connect(_on_body_entered)
	
	# Создаём коллизию
	var shape = CircleShape2D.new()
	shape.radius = LEVEL_DATA[level]["radius"]
	var col = CollisionShape2D.new()
	col.shape = shape
	add_child(col)
	
	# Анимация появления
	scale = Vector2.ZERO
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector2.ONE, 0.1)

func _draw() -> void:
	var data = LEVEL_DATA[level]
	var r: float = data["radius"]
	var col: Color = data["color"]
	
	draw_circle(Vector2.ZERO, r * 2.2, Color(col.r, col.g, col.b, 0.10))
	draw_circle(Vector2.ZERO, r * 1.6, Color(col.r, col.g, col.b, 0.20))
	draw_circle(Vector2.ZERO, r * 1.2, Color(col.r, col.g, col.b, 0.50))
	draw_circle(Vector2.ZERO, r, col)
	draw_circle(Vector2.ZERO, r * 0.4, Color(1, 1, 0.8, 0.95))
	
	if level >= 3:
		for i in 6:
			var angle = i * PI / 3.0
			var sp = Vector2(cos(angle), sin(angle)) * r * 1.35
			draw_circle(sp, r * 0.18, Color(1.0, 0.8, 0.0, 0.85))
	
	if level >= 4:
		for i in 8:
			var angle = i * PI / 4.0
			var sp = Vector2(cos(angle), sin(angle)) * r * 1.7
			draw_circle(sp, r * 0.24, Color(0.6, 0.0, 0.0, 0.80))

func _physics_process(delta: float) -> void:
	_lifetime += delta
	if _lifetime >= _max_lifetime:
		var tw = create_tween()
		tw.tween_property(self, "modulate:a", 0.0, 0.15)
		tw.tween_callback(queue_free)
		set_physics_process(false)
		return
	
	position += direction * speed * delta
	var pulse = 1.0 + sin(_lifetime * 14.0) * 0.07
	scale = Vector2(pulse, pulse)
	queue_redraw()

func _on_body_entered(body: Node) -> void:
	print("🔥 Шар попал в:", body.name, "группы:", body.get_groups())
	
	if body.is_in_group("player"):
		return
	
	if body.has_method("take_damage"):
		body.take_damage(damage)
		print("💥 Урон нанесён:", damage)
	else:
		print("⚠️ У объекта нет take_damage!")
	
	_explode()
	queue_free()

func _explode() -> void:
	pass
