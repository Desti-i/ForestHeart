extends Node

var has_boss_key: bool = false
var spawn_point_name: String = "SpawnPoint"

# EXP как валюта
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

var sword_level: int = 0
signal sword_upgraded(new_level: int)

var sword_levels: Array = [
	{
		"level": 0,
		"name": "Меч",
		"damage": 5.0,
		"anim_prefix": "attack_1_",   # название анимации для 1 уровня
		"cost": 0,
		"color": Color(1.0, 1.0, 1.0),
		"description": "Обычный меч"
	},
	{
		"level": 1,
		"name": "Меч",
		"damage": 7.0,
		"anim_prefix": "attack_2_",   # название анимации для 2 уровня
		"cost": 100,
		"color": Color(1.0, 0.9, 0.2),
		"description": "Накалённый меч"
	},
	{
		"level": 2,
		"name": "Меч",
		"damage": 10.0,
		"anim_prefix": "attack_3_",   # название анимации для 3 уровня
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

signal weapon_changed(weapon: Dictionary)

# Заглушки для совместимости
func select_weapon(_index: int) -> void: pass
func unlock_weapon(_index: int) -> bool: return false
var active_weapon_index: int = 0
