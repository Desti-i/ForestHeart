extends CharacterBody2D

signal health_changed(new_health, max_health)
signal stamina_changed(cur: float, max_val: float)

enum DIRECTION { DOWN, UP, LEFT, RIGHT }

@onready var anim  = $Movements
@onready var animP = $AnimationPlayer
@onready var hp_bar   = $"../CanvasLayer/Control/hp_bar"
@onready var hp_label = $"../CanvasLayer/Control/hp_bar/Label"
@onready var q_menu   = $"../CanvasLayer/QMenu"

var max_health:     float = 100
var current_health: float = max_health
var damage:         float = 5.0

const WALK_SPEED: float = 100.0
const RUN_SPEED:  float = 200.0

var current_speed:    float     = WALK_SPEED
var idle_dir:         DIRECTION = DIRECTION.DOWN
var input_direction   := Vector2.ZERO
var can_move:         bool      = true
var is_invincible:    bool      = false
var _q_menu_open:     bool      = false

@export var max_stamina:       float = 100.0
@export var stamina_regen:     float = 22.0
@export var run_stamina_cost:  float = 16.0
@export var dash_stamina_cost: float = 25.0
var stamina: float

@export var dash_speed:    float = 480.0
@export var dash_duration: float = 0.16
@export var dash_cooldown: float = 0.9

var _dashing:    bool    = false
var _dash_timer: float   = 0.0
var _dash_cd:    float   = 0.0
var _dash_dir:   Vector2 = Vector2.ZERO

var _fire_cd:  float = 0.0
var _water_cd: float = 0.0
var _ice_cd:   float = 0.0
var _heal_cd:  float = 0.0
var _blood_cd: float = 0.0

func _ready() -> void:
	stamina = max_stamina
	if hp_bar:
		hp_bar.max_value = max_health
		hp_bar.min_value = 0
		hp_bar.value     = current_health
	if hp_label:
		hp_label.text = "100/100"
		hp_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	_update_hp_label()
	damage = GameState.get_active_weapon()["damage"]
	GameState.weapon_changed.connect(_on_weapon_changed)
	if q_menu:
		q_menu.visible = false

func update_max_health(new_max: float) -> void:
	var old_max = max_health
	max_health = new_max
	
	# Пропорционально увеличиваем текущее здоровье
	var health_ratio = current_health / old_max
	current_health = max_health * health_ratio
	current_health = clamp(current_health, 1, max_health)
	
	# Обновляем HP бар
	if hp_bar:
		hp_bar.max_value = max_health
		hp_bar.value = current_health
	
	health_changed.emit(current_health, max_health)
	_update_hp_label()
	
	print("❤️ Максимальное здоровье увеличено: ", old_max, " → ", max_health)

func _on_weapon_changed(weapon: Dictionary) -> void:
	damage = weapon["damage"]
	print("⚔️ Меч улучшен! Урон:", weapon["damage"])

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("heal_magic"):
		_cast_heal()

func _physics_process(delta: float) -> void:
	_dash_cd  = max(0.0, _dash_cd  - delta)
	_fire_cd  = max(0.0, _fire_cd  - delta)
	_water_cd = max(0.0, _water_cd - delta)
	_ice_cd   = max(0.0, _ice_cd   - delta)
	_blood_cd = max(0.0, _blood_cd - delta) 
	_heal_cd  = max(0.0, _heal_cd  - delta)

	if _dashing:
		_dash_timer -= delta
		velocity = _dash_dir * dash_speed
		move_and_slide()
		modulate.a = 0.5 if int(_dash_timer * 20) % 2 == 0 else 1.0
		if _dash_timer <= 0.0:
			_dashing      = false
			is_invincible = false
			modulate.a    = 1.0
			velocity      = Vector2.ZERO
		return

	if Input.is_action_just_pressed("open_menu"):
		_toggle_q_menu()
		return

	if _q_menu_open:
		return

	if !can_move:
		return

	if Input.is_action_just_pressed("fire_magic"):
		_cast_attack_magic()
		return

	if Input.is_action_just_pressed("atack"):
		handle_attack()
		return

	if Input.is_action_just_pressed("dash") and _dash_cd <= 0.0 and stamina >= dash_stamina_cost and stamina > max_stamina * 0.1:
		_start_dash()
		return

	input_direction = Input.get_vector("left", "right", "up", "down").normalized()
	var running = Input.is_action_pressed("run") and input_direction != Vector2.ZERO

	if running:
		stamina = max(0.0, stamina - run_stamina_cost * delta)
		emit_signal("stamina_changed", stamina, max_stamina)

	current_speed = RUN_SPEED if (running and stamina > max_stamina * 0.1) else WALK_SPEED
	velocity = input_direction * current_speed

	if not running:
		var prev := stamina
		stamina = min(max_stamina, stamina + stamina_regen * delta)
		if stamina != prev:
			emit_signal("stamina_changed", stamina, max_stamina)

	handle_movements()
	move_and_slide()



# ── МАГИЯ ────────────────────────────────────────────────

func _cast_blood() -> void:
	if GameState.blood_magic_level == 0:
		_show_hint("🩸 Магия крови не открыта! Открой в меню Q")
		return
	
	var blood_data = GameState.get_blood_magic()
	if _blood_cd > 0.0:
		_show_hint("🩸 Перезарядка: " + str(snapped(_blood_cd, 0.1)) + "с")
		return
	
	_blood_cd = blood_data["cooldown"]
	var dir = _facing_vector()
	var lvl = GameState.blood_magic_level
	
	_spawn_bloodball(lvl, dir)

func _spawn_bloodball(lvl: int, dir: Vector2) -> void:
	var bb = Area2D.new()
	bb.set_script(load("res://magic/BloodBall.gd"))
	bb.global_position = global_position + dir * 20.0
	bb.z_index = 10
	get_parent().add_child(bb)
	bb.setup(lvl, dir)

func _cast_attack_magic() -> void:
	match GameState.active_magic:
		"fire":  _cast_fire()
		"water": _cast_water()
		"ice":   _cast_ice()
		"blood": _cast_blood()
		_: _show_hint("⚔️ Сначала выбери магию в меню Q")



func _cast_fire() -> void:
	if GameState.fire_magic_level == 0:
		_show_hint("🔥 Магия огня не открыта! Открой в меню Q")
		return
	var fire_data = GameState.get_fire_magic()
	if _fire_cd > 0.0:
		_show_hint("🔥 Перезарядка: " + str(snapped(_fire_cd, 0.1)) + "с")
		return
	_fire_cd = fire_data["cooldown"]
	var dir = _facing_vector()
	var lvl = GameState.fire_magic_level
	if lvl == 4:
		for a in [-0.3, 0.0, 0.3]:
			_spawn_fireball(lvl, dir.rotated(a))
	else:
		_spawn_fireball(lvl, dir)

func _spawn_fireball(lvl: int, dir: Vector2) -> void:
	var fb = Area2D.new()
	fb.set_script(load("res://magic/FireBall.gd"))
	fb.global_position = global_position + dir * 20.0
	fb.z_index = 10
	get_parent().add_child(fb)
	fb.setup(lvl, dir)

func _cast_water() -> void:
	if not GameState.water_magic_unlocked:
		_show_hint("💧 Магия воды не получена!")
		return
	var water_data = GameState.get_water_magic()
	if _water_cd > 0.0:
		_show_hint("💧 Перезарядка: " + str(snapped(_water_cd, 0.1)) + "с")
		return
	_water_cd = water_data["cooldown"]
	var dir = _facing_vector()
	var wb = Area2D.new()
	wb.set_script(load("res://magic/WaterBall.gd"))
	wb.global_position = global_position + dir * 20.0
	wb.z_index = 10
	get_parent().add_child(wb)
	wb.setup(GameState.water_magic_level, dir)

func _cast_ice() -> void:
	if GameState.ice_magic_level == 0:
		_show_hint("❄️ Магия льда не открыта! Открой в меню Q")
		return
	var ice_data = GameState.get_ice_magic()
	if _ice_cd > 0.0:
		_show_hint("❄️ Перезарядка: " + str(snapped(_ice_cd, 0.1)) + "с")
		return
	_ice_cd = ice_data["cooldown"]
	var dir = _facing_vector()
	var lvl = GameState.ice_magic_level
	if lvl == 3:
		for a in [-0.35, 0.0, 0.35]:
			_spawn_iceball(lvl, dir.rotated(a))
	else:
		_spawn_iceball(lvl, dir)

func _spawn_iceball(lvl: int, dir: Vector2) -> void:
	var ib = Area2D.new()
	ib.set_script(load("res://magic/IceBall.gd"))
	ib.global_position = global_position + dir * 20.0
	ib.z_index = 10
	get_parent().add_child(ib)
	ib.setup(lvl, dir)

func _cast_heal() -> void:
	if not GameState.heal_magic_unlocked:
		_show_hint("💚 Магия лечения не получена!")
		return
	if current_health >= max_health:
		_show_hint("❤️ У тебя уже полное здоровье!")
		return
	var heal_data = GameState.get_heal_magic()
	if _heal_cd > 0.0:
		_show_hint("💚 Перезарядка: " + str(snapped(_heal_cd, 0.1)) + "с")
		return
	var heal_amount = heal_data["heal_amount"]
	current_health = min(current_health + heal_amount, max_health)
	if hp_bar:
		hp_bar.value = current_health
	health_changed.emit(current_health, max_health)
	_update_hp_label()
	_show_heal_effect(heal_amount)
	_heal_cd = heal_data["cooldown"]
	print("💚 Вылечено +", heal_amount, " HP!")

func _show_heal_effect(amount: float) -> void:
	var lbl := Label.new()
	lbl.text = "+" + str(int(amount)) + " ❤️"
	lbl.add_theme_color_override("font_color", Color(0.2, 1.0, 0.3))
	lbl.add_theme_constant_override("outline_size", 2)
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.position = global_position + Vector2(-30, -80)
	lbl.z_index = 100
	get_parent().add_child(lbl)
	var tw = create_tween()
	tw.tween_property(lbl, "position:y", lbl.position.y - 40, 1.0)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 1.0)
	tw.tween_callback(lbl.queue_free)
	modulate = Color(0.5, 1.0, 0.5)
	await get_tree().create_timer(0.2).timeout
	modulate = Color.WHITE

func _show_hint(msg: String) -> void:
	var lbl := Label.new()
	lbl.text = msg
	lbl.add_theme_color_override("font_color", Color.ORANGE)
	lbl.add_theme_constant_override("outline_size", 2)
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.add_theme_font_size_override("font_size", 15)
	lbl.position = global_position + Vector2(-80, -70)
	lbl.z_index = 100
	get_parent().add_child(lbl)
	var tw = create_tween()
	tw.tween_property(lbl, "position:y", lbl.position.y - 30, 1.2)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 1.2)
	tw.tween_callback(lbl.queue_free)

# ── МЕНЮ Q ───────────────────────────────────────────────
func _toggle_q_menu() -> void:
	if q_menu:
		_q_menu_open = !_q_menu_open
		q_menu.visible = _q_menu_open
		can_move = !_q_menu_open
		if _q_menu_open:
			q_menu.refresh()

func _start_dash() -> void:
	_dash_dir     = input_direction if input_direction != Vector2.ZERO else _facing_vector()
	_dashing      = true
	_dash_timer   = dash_duration
	_dash_cd      = dash_cooldown
	stamina      -= dash_stamina_cost
	is_invincible = true
	emit_signal("stamina_changed", stamina, max_stamina)

func _facing_vector() -> Vector2:
	match idle_dir:
		DIRECTION.DOWN:  return Vector2.DOWN
		DIRECTION.UP:    return Vector2.UP
		DIRECTION.LEFT:  return Vector2.LEFT
		DIRECTION.RIGHT: return Vector2.RIGHT
	return Vector2.DOWN

func handle_movements() -> void:
	if input_direction != Vector2.ZERO:
		if abs(input_direction.x) > abs(input_direction.y):
			if input_direction.x > 0:
				anim.play("Right"); idle_dir = DIRECTION.RIGHT
			else:
				anim.play("Left");  idle_dir = DIRECTION.LEFT
		else:
			if input_direction.y > 0:
				anim.play("Down"); idle_dir = DIRECTION.DOWN
			else:
				anim.play("Up");   idle_dir = DIRECTION.UP
	else:
		anim.play("idle_" + get_direction_string())

func handle_attack() -> void:
	can_move = false
	velocity  = Vector2.ZERO
	var weapon = GameState.get_active_weapon()
	animP.play(weapon["anim_prefix"] + get_direction_string())
	await animP.animation_finished
	can_move = true

func take_damage(incoming_damage: float) -> void:
	if is_invincible:
		return
	current_health -= incoming_damage
	current_health  = max(current_health, 0)
	if hp_bar:
		hp_bar.value = current_health
	health_changed.emit(current_health, max_health)
	_update_hp_label()
	modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	modulate = Color.WHITE
	if current_health <= 0:
		die()

func heal(amount: float) -> void:
	current_health = min(current_health + amount, max_health)
	if hp_bar:
		hp_bar.value = current_health
	health_changed.emit(current_health, max_health)
	_update_hp_label()

func die() -> void:
	if current_health > 0: return
	
	set_physics_process(false)
	set_process_input(false)
	can_move = false
	
	# Анимация смерти
	if anim and anim.sprite_frames.has_animation("death"):
		anim.play("death")
		await anim.animation_finished
	
	# Проверяем, где мы находимся
	var current_scene_path = get_tree().current_scene.scene_file_path
	
	# Если мы уже на 3 локации, просто вызываем функцию респавна на месте
	if "location3" in current_scene_path.to_lower():
		_respawn_on_third_location()
	else:
		# Иначе переходим в деревню
		get_tree().change_scene_to_file("res://locations/primary_village/Vilage1.tscn")
		# После смены сцены нужно дождаться инициализации, чтобы найти SpawnPoint
		await get_tree().process_frame
		_finish_respawn()

func _do_respawn(target_scene: String) -> void:
	if is_inside_tree():
		get_tree().change_scene_to_file(target_scene)

func _stop_all_enemies() -> void:
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(enemy):
			continue
		if not enemy is CharacterBody2D:
			continue
		enemy.set_physics_process(false)
		enemy.velocity = Vector2.ZERO
		if enemy.has_node("StateMachine"):
			var sm = enemy.get_node("StateMachine")
			if sm.has_node("Idle"):
				sm.change_state("Idle")

func _respawn() -> void:
	print("🔄 Начинаем респавн...")
	
	# Восстанавливаем здоровье
	current_health = max_health
	stamina = max_stamina
	
	# Определяем текущую сцену
	var current_scene_path = get_tree().current_scene.scene_file_path
	print("📍 Текущая сцена: ", current_scene_path)
	
	# 👇 ИСПРАВЛЕНО: ищем "location3" или "Location3"
	if current_scene_path.find("location3") != -1 or current_scene_path.find("Location3") != -1:
		# На 3 локации - просто телепортируем на SpawnPoint
		print("✅ Возрождение на 3 локации")
		var spawn_point = get_tree().current_scene.get_node_or_null("SpawnPoint")
		if spawn_point:
			global_position = spawn_point.global_position
			print("✅ Телепорт на SpawnPoint 3 локации: ", global_position)
		else:
			print("⚠️ SpawnPoint не найден на 3 локации")
		
		# Восстанавливаем управление
		_finish_respawn()
		print("✅ Возрождён на 3 локации!")
	else:
		# На других локациях - переходим в деревню
		print("🔄 Переход в деревню...")
		
		# Меняем сцену
		get_tree().change_scene_to_file("res://locations/primary_village/Vilage1.tscn")
		
		# Ждём загрузки новой сцены
		await get_tree().process_frame
		await get_tree().process_frame
		
		# Находим SpawnPoint в деревне
		var spawn_point = get_tree().current_scene.get_node_or_null("SpawnPoint")
		if spawn_point:
			global_position = spawn_point.global_position
			print("✅ Телепорт на SpawnPoint деревни: ", global_position)
		
		# Восстанавливаем управление
		_finish_respawn()
		print("✅ Возрождён в деревне!")



func _respawn_on_third_location():
	print("🔄 Возрождение на 3 локации...")
	
	# 1. Восстанавливаем статы
	current_health = max_health
	stamina = max_stamina
	
	# 2. Ищем точку спавна
	var spawn_point = get_tree().current_scene.get_node_or_null("SpawnPoint")
	if spawn_point:
		global_position = spawn_point.global_position
	else:
		printerr("⚠️ ОШИБКА: SpawnPoint не найден на этой сцене!")
	
	# 3. Возвращаем управление
	_finish_respawn()

func _respawn_in_village():
	print("🔄 Респавн в деревне...")
	
	# Сохраняем данные
	var saved_health = max_health
	var saved_stamina = max_stamina
	
	# Меняем сцену
	get_tree().change_scene_to_file("res://locations/primary_village/Vilage1.tscn")
	
	# Ждём загрузки
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Восстанавливаем здоровье
	current_health = saved_health
	stamina = saved_stamina
	
	# Ищем SpawnPoint
	var spawn_point = get_tree().current_scene.get_node_or_null("SpawnPoint")
	if spawn_point:
		global_position = spawn_point.global_position
		print("✅ Телепорт на SpawnPoint")
	
	# Восстанавливаем управление
	set_physics_process(true)
	set_process_input(true)
	can_move = true
	is_invincible = false
	modulate = Color.WHITE
	
	# Обновляем HP бар
	if hp_bar:
		hp_bar.max_value = max_health
		hp_bar.value = current_health
	_update_hp_label()
	
	# Переподключаем сигналы
	if not GameState.weapon_changed.is_connected(_on_weapon_changed):
		GameState.weapon_changed.connect(_on_weapon_changed)
	
	damage = GameState.get_active_weapon()["damage"]
	
	print("✅ Возрождён в деревне!")

func _finish_respawn() -> void:
	# Возвращаем в группу
	remove_from_group("dead")
	add_to_group("player")
	
	# Включаем управление
	set_physics_process(true)
	set_process_input(true)
	can_move = true
	is_invincible = false
	modulate = Color.WHITE
	_q_menu_open = false
	
	# Обновляем HP бар
	if hp_bar:
		hp_bar.max_value = max_health
		hp_bar.value = current_health
	_update_hp_label()
	
	# Переподключаем сигнал оружия
	if not GameState.weapon_changed.is_connected(_on_weapon_changed):
		GameState.weapon_changed.connect(_on_weapon_changed)
	
	damage = GameState.get_active_weapon()["damage"]
	
	print("✅ Респавн завершён! HP:", current_health)
	if GameState.is_respawning:
		var sp = get_tree().current_scene.get_node_or_null("SpawnPoint")
		if sp:
			global_position = sp.global_position
		GameState.is_respawning = false

func get_direction_string() -> String:
	match idle_dir:
		DIRECTION.DOWN:  return "down"
		DIRECTION.UP:    return "up"
		DIRECTION.LEFT:  return "left"
		DIRECTION.RIGHT: return "right"
	return "down"

func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage, "physical")

func _update_hp_label() -> void:
	if hp_label:
		hp_label.text = str(int(current_health)) + " / " + str(int(max_health))
		hp_label.remove_theme_color_override("font_color")
		hp_label.remove_theme_color_override("font_outline_color")
		hp_label.remove_theme_constant_override("outline_size")
		hp_label.add_theme_constant_override("outline_size", 2)
		hp_label.add_theme_color_override("font_outline_color", Color.BLACK)
		var health_percent = current_health / max_health
		if health_percent <= 0.2:
			hp_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
		elif health_percent <= 0.5:
			hp_label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.2))
		else:
			hp_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
		hp_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
		hp_label.add_theme_constant_override("shadow_offset_x", 1)
		hp_label.add_theme_constant_override("shadow_offset_y", 1)
		hp_label.scale = Vector2(1.1, 1.1)
		await get_tree().create_timer(0.1).timeout
		hp_label.scale = Vector2(1.0, 1.0)
