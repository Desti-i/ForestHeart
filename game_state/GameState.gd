extends Node

# ─── Глобальное состояние игры ───────────────────────────

var has_boss_key: bool = false
var spawn_point_name: String = "SpawnPoint"

# ─── EXP как валюта ──────────────────────────────────────
var exp: int = 0

signal exp_changed(new_amount: int)

func _ready() -> void:
	print("✅ GameState загружен. EXP:", exp)

## Добавить EXP (вызывается когда моб умирает)
func add_exp(amount: int) -> void:
	exp += amount
	print("⭐ +", amount, " EXP! Всего: ", exp)
	emit_signal("exp_changed", exp)

## Потратить EXP (вызывается когда покупаешь оружие/магию)
## Возвращает true если хватило денег, false если нет
func spend_exp(amount: int) -> bool:
	if exp >= amount:
		exp -= amount
		print("💸 Потрачено:", amount, " EXP. Осталось:", exp)
		emit_signal("exp_changed", exp)
		return true
	else:
		print("❌ Не хватает EXP! Нужно:", amount, " Есть:", exp)
		return false
