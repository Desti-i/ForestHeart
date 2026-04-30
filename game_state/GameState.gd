extends Node

# ─── Глобальное состояние ────────────────────────────────
var has_boss_key: bool = false
var spawn_point_name: String = "SpawnPoint"

# ─── EXP как валюта ──────────────────────────────────────
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

# ─── Оружия ──────────────────────────────────────────────
# Каждое оружие: { name, damage, anim_prefix, unlocked, cost }
var weapons: Array = [
	{
		"id": "sword_1",
		"name": "Простой меч",
		"damage": 5.0,
		"anim_prefix": "attack_1_",
		"unlocked": true,   # первое оружие доступно сразу
		"cost": 0
	},
	{
		"id": "sword_2",
		"name": "Длинный меч",
		"damage": 12.0,
		"anim_prefix": "attack_1_",  # пока та же анимация, потом поменяешь
		"unlocked": false,
		"cost": 100
	},
	{
		"id": "sword_3",
		"name": "Боевой топор",
		"damage": 20.0,
		"anim_prefix": "attack_1_",
		"unlocked": false,
		"cost": 250
	},
]

## Индекс текущего активного оружия
var active_weapon_index: int = 0

signal weapon_changed(weapon: Dictionary)

func get_active_weapon() -> Dictionary:
	return weapons[active_weapon_index]

func select_weapon(index: int) -> void:
	if index < 0 or index >= weapons.size():
		return
	if not weapons[index]["unlocked"]:
		print("❌ Оружие заблокировано!")
		return
	active_weapon_index = index
	print("⚔️ Выбрано оружие:", weapons[index]["name"])
	emit_signal("weapon_changed", weapons[index])

func unlock_weapon(index: int) -> bool:
	var w = weapons[index]
	if w["unlocked"]:
		print("Уже разблокировано!")
		return false
	if spend_exp(w["cost"]):
		weapons[index]["unlocked"] = true
		print("🔓 Разблокировано:", w["name"])
		return true
	else:
		print("❌ Не хватает EXP! Нужно:", w["cost"])
		return false
