extends Node

var has_boss_key: bool = false
var spawn_point_name: String = "SpawnPoint"

# ─── EXP ─────────────────────────────────────────────────
var exp: int = 0
signal exp_changed(new_amount: int)

func add_exp(amount: int) -> void:
	exp += amount
	print("⭐ +", amount, " EXP! Всего: ", exp)
	emit_signal("exp_changed", exp)

func spend_exp(amount: int) -> bool:
	if exp >= amount:
		exp -= amount
		emit_signal("exp_changed", exp)
		return true
	return false

# ─── МЕЧ ─────────────────────────────────────────────────
var sword_level: int = 0
signal sword_upgraded(new_level: int)
signal weapon_changed(weapon: Dictionary)

var sword_levels: Array = [
	{
		"level": 0,
		"name": "Меч",
		"damage": 5.0,
		"anim_prefix": "attack_1_",
		"idle_prefix": "",        # пустой = стандартные анимации (Down, Up, idle_down...)
		"cost": 0,
		"color": Color(1.0, 1.0, 1.0),
		"description": "Обычный меч"
	},
	{
		"level": 1,
		"name": "Меч",
		"damage": 7.0,
		"anim_prefix": "attack_2_",
		"idle_prefix": "s2_",     # анимации s2_Down, s2_Up, s2_idle_down...
		"cost": 100,
		"color": Color(1.0, 0.9, 0.2),
		"description": "Накалённый меч"
	},
	{
		"level": 2,
		"name": "Меч",
		"damage": 10.0,
		"anim_prefix": "attack_3_",
		"idle_prefix": "s3_",     # анимации s3_Down, s3_Up, s3_idle_down...
		"cost": 250,
		"color": Color(0.3, 0.8, 1.0),
		"description": "Ледяной меч"
	},
]

func get_active_weapon() -> Dictionary:
	return sword_levels[sword_level]

func can_upgrade_sword() -> bool:
	return sword_level < sword_levels.size() - 1

func upgrade_sword() -> bool:
	if not can_upgrade_sword():
		print("❌ Меч уже максимального уровня!")
		return false
	var next = sword_levels[sword_level + 1]
	if spend_exp(next["cost"]):
		sword_level += 1
		print("⚔️ Меч улучшен до уровня:", sword_level)
		emit_signal("sword_upgraded", sword_level)
		emit_signal("weapon_changed", get_active_weapon())
		return true
	print("❌ Не хватает EXP! Нужно:", next["cost"])
	return false

func select_weapon(_index: int) -> void: pass
func unlock_weapon(_index: int) -> bool: return false
var active_weapon_index: int = 0

# ─── МАГИЯ ОГНЯ ──────────────────────────────────────────
## Уровень магии огня (0 = не открыта)
var fire_magic_level: int = 0

signal fire_magic_upgraded(new_level: int)

## Данные каждого уровня магии
var fire_magic_levels: Array = [
	{
		"level": 0, "name": "Не открыта",
		"damage": 0.0, "cost": 50,
		"color": Color(0.5, 0.5, 0.5),
		"description": "Открыть магию огня",
		"radius": 0.0, "speed": 0.0
	},
	{
		"level": 1, "name": "Огненный шар",
		"damage": 10.0, "cost": 0,
		"color": Color(1.0, 0.5, 0.0),
		"description": "Маленький огненный шар",
		"radius": 7.0, "speed": 260.0
	},
	{
		"level": 2, "name": "Огненный шар II",
		"damage": 22.0, "cost": 150,
		"color": Color(1.0, 0.75, 0.0),
		"description": "Большой горящий шар",
		"radius": 11.0, "speed": 320.0
	},
	{
		"level": 3, "name": "Огненный шар III",
		"damage": 40.0, "cost": 300,
		"color": Color(1.0, 0.25, 0.0),
		"description": "Огромный шар с искрами",
		"radius": 16.0, "speed": 380.0
	},
	{
		"level": 4, "name": "Адский огонь",
		"damage": 70.0, "cost": 500,
		"color": Color(0.8, 0.0, 0.0),
		"description": "Тёмное пламя ада",
		"radius": 22.0, "speed": 440.0
	},
]

func get_fire_magic() -> Dictionary:
	if fire_magic_level == 0:
		return fire_magic_levels[0]
	return fire_magic_levels[fire_magic_level]

func can_upgrade_fire() -> bool:
	return fire_magic_level < fire_magic_levels.size() - 1

## Открыть или прокачать магию огня
func upgrade_fire_magic() -> bool:
	if fire_magic_level == 0:
		# Первый раз — открываем за 50 EXP
		if spend_exp(fire_magic_levels[0]["cost"]):
			fire_magic_level = 1
			print("🔥 Магия огня открыта! Уровень 1")
			emit_signal("fire_magic_upgraded", fire_magic_level)
			return true
		print("❌ Нужно 50 EXP чтобы открыть магию")
		return false

	if not can_upgrade_fire():
		print("🔥 Магия огня максимального уровня!")
		return false

	var next_level = fire_magic_level + 1
	var cost = fire_magic_levels[next_level]["cost"]
	if spend_exp(cost):
		fire_magic_level = next_level
		print("🔥 Магия огня улучшена до уровня:", fire_magic_level)
		emit_signal("fire_magic_upgraded", fire_magic_level)
		return true

	print("❌ Не хватает EXP! Нужно:", cost)
	return false
