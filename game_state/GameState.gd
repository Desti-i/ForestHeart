extends Node

var has_boss_key: bool = false
var spawn_point_name: String = "SpawnPoint"
var boss_defeated: bool = false
var tutorial_completed: bool = false

# ─── РЕПУТАЦИЯ ───────────────────────────────────────────
var reputation: int = 0
signal reputation_changed(value: int)

func change_reputation(amount: int) -> void:
	reputation = clamp(reputation + amount, -100, 100)
	print("👤 Репутация:", reputation)
	emit_signal("reputation_changed", reputation)

func get_health_from_heal_level() -> float:
	match heal_magic_level:
		0: return 100   # Базовое HP
		1: return 120   # +20 HP
		2: return 145   # +45 HP
		3: return 175   # +75 HP
		4: return 210   # +110 HP
	return 100


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
var sword_lvl3_dropped: bool = false
signal sword_upgraded(new_level: int)
signal weapon_changed(weapon: Dictionary)

var sword_levels: Array = [
	{
		"level": 0,
		"name": "Меч",
		"damage": 45.0,
		"anim_prefix": "attack_1_",
		"idle_prefix": "",
		"cost": 0,
		"color": Color(1.0, 1.0, 1.0),
		"description": "Обычный меч"
	},
	{
		"level": 1,
		"name": "Накалённый меч",
		"damage": 12.0,
		"anim_prefix": "attack_2_",
		"idle_prefix": "s2_",
		"cost": 300,
		"color": Color(1.0, 0.9, 0.2),
		"description": "Накалённый меч"
	},
	{
		"level": 2,
		"name": "Закалённый меч",
		"damage": 25.0,
		"anim_prefix": "attack_3_",
		"idle_prefix": "s3_",
		"cost": 2225,
		"color": Color(0.3, 0.8, 1.0),
		"description": "Закалённый меч"
	},
	{
		"level": 3,
		"name": "Тёмный клинок",
		"damage": 35.0,
		"anim_prefix": "attack_4_",
		"idle_prefix": "s4_",
		"cost": 5000,
		"color": Color(0.8, 0.2, 1.0),
		"description": "Тёмный клинок"
	},
]

func get_active_weapon() -> Dictionary:
	return sword_levels[sword_level]

func can_upgrade_sword() -> bool:
	return sword_level < sword_levels.size() - 1

func unlock_sword_lvl3() -> void:
	if sword_lvl3_dropped:
		return
	sword_lvl3_dropped = true
	SaveManager.game_data.stats.sword_lvl3_dropped = sword_lvl3_dropped
	print("⚔️ Ледяной меч выпал! Теперь можно купить в меню.")
	emit_signal("sword_upgraded", sword_level)

func upgrade_sword() -> bool:
	if not can_upgrade_sword():
		print("❌ Меч уже максимального уровня!")
		return false
	var next = sword_levels[sword_level + 1]
	
	if sword_level + 1 == 2 and not sword_lvl3_dropped:
		print("❌ Ледяной меч ещё не выпал! Убей ледяную слизь!")
		return false
	
	if spend_exp(next["cost"]):
		sword_level += 1
		SaveManager.game_data.stats.sword_level = sword_level
		print("⚔️ Меч улучшен до уровня:", sword_level)
		emit_signal("sword_upgraded", sword_level)
		emit_signal("weapon_changed", get_active_weapon())
		return true
	print("❌ Не хватает EXP! Нужно:", next["cost"])
	return false

func select_weapon(_index: int) -> void: pass
func unlock_weapon(_index: int) -> bool: return false
var active_weapon_index: int = 0

# ─── ОГНЕННЫЙ МЕЧ ────────────────────────────────────────
var fire_sword_unlocked: bool = false
var fire_sword_level: int = 0
signal fire_sword_upgraded(new_level: int)

var fire_sword_levels: Array = [
	{
		"level": 0, "name": "Не получен",
		"damage": 0.0, "anim_prefix": "", "idle_prefix": "",
		"cost": 0, "color": Color(0.5, 0.5, 0.5),
		"description": "Выпадает с огненных слизей"
	},
	{
		"level": 1, "name": "Огненный меч",
		"damage": 12.0, "anim_prefix": "fire_attack_", "idle_prefix": "fire_",
		"cost": 0, "color": Color(1.0, 0.5, 0.0),
		"description": "Меч из огненной слизи"
	},
	{
		"level": 2, "name": "Огненный меч II",
		"damage": 22.0, "anim_prefix": "fire_attack_2_", "idle_prefix": "fire2_",
		"cost": 180, "color": Color(1.0, 0.6, 0.0),
		"description": "Улучшенный огненный меч"
	},
	{
		"level": 3, "name": "Огненный меч III",
		"damage": 35.0, "anim_prefix": "fire_attack_3_", "idle_prefix": "fire3_",
		"cost": 350, "color": Color(1.0, 0.3, 0.0),
		"description": "Магматический меч"
	},
	{
		"level": 4, "name": "Пылающий клинок",
		"damage": 55.0, "anim_prefix": "fire_attack_4_", "idle_prefix": "fire4_",
		"cost": 600, "color": Color(1.0, 0.1, 0.0),
		"description": "Клинок древнего вулкана"
	},
]

func get_active_fire_sword() -> Dictionary:
	if fire_sword_level == 0:
		return fire_sword_levels[0]
	return fire_sword_levels[fire_sword_level]

func can_upgrade_fire_sword() -> bool:
	return fire_sword_unlocked and fire_sword_level < fire_sword_levels.size() - 1

func unlock_fire_sword() -> void:
	if fire_sword_unlocked:
		return
	fire_sword_unlocked = true
	SaveManager.game_data.stats.fire_sword_unlocked = fire_sword_unlocked
	fire_sword_level = 1
	print("⚔️ Огненный меч получен!")
	emit_signal("fire_sword_upgraded", fire_sword_level)

func upgrade_fire_sword() -> bool:
	if not fire_sword_unlocked:
		print("⚔️ Огненный меч ещё не получен!")
		return false
	if not can_upgrade_fire_sword():
		print("⚔️ Огненный меч максимального уровня!")
		return false
	var next_level = fire_sword_level + 1
	var cost = fire_sword_levels[next_level]["cost"]
	if spend_exp(cost):
		fire_sword_level = next_level
		SaveManager.game_data.stats.fire_sword_level = fire_sword_level
		print("⚔️ Огненный меч улучшен до уровня:", fire_sword_level)
		emit_signal("fire_sword_upgraded", fire_sword_level)
		return true
	print("❌ Не хватает EXP! Нужно:", cost)
	return false

# ─── АКТИВНАЯ МАГИЯ ──────────────────────────────────────
var active_magic: String = "fire"
signal active_magic_changed(magic_type: String)

func set_active_magic(type: String) -> void:
	if type == "heal" and not heal_magic_unlocked:
		print("💚 Магия лечения ещё не открыта!")
		return
	if type == "blood" and blood_magic_level == 0:
		print("🩸 Магия крови ещё не открыта!")
		return
	active_magic = type
	print("✨ Активная магия:", type)
	emit_signal("active_magic_changed", type)

func get_active_magic_level() -> int:
	match active_magic:
		"fire":  return fire_magic_level
		"water": return water_magic_level
		"heal":  return heal_magic_level
		"blood": return blood_magic_level
	return 0

# ─── МАГИЯ ОГНЯ ──────────────────────────────────────────
var fire_magic_level: int = 0
signal fire_magic_upgraded(new_level: int)

var fire_magic_levels: Array = [
	{
		"level": 0, "name": "Не открыта",
		"damage": 0.0, "cost": 250,
		"color": Color(0.5, 0.5, 0.5),
		"description": "Открыть магию огня",
		"radius": 0.0, "speed": 0.0, "cooldown": 0.0
	},
	{
		"level": 1, "name": "Огненный шар",
		"damage": 10.0, "cost": 0,
		"color": Color(1.0, 0.5, 0.0),
		"description": "Маленький огненный шар",
		"radius": 7.0, "speed": 260.0, "cooldown": 2.0
	},
	{
		"level": 2, "name": "Огненный шар II",
		"damage": 22.0, "cost": 1150,
		"color": Color(1.0, 0.75, 0.0),
		"description": "Большой горящий шар",
		"radius": 11.0, "speed": 320.0, "cooldown": 1.7
	},
	{
		"level": 3, "name": "Огненный шар III",
		"damage": 40.0, "cost": 3000,
		"color": Color(1.0, 0.25, 0.0),
		"description": "Огромный шар с искрами",
		"radius": 16.0, "speed": 380.0, "cooldown": 1.5
	},
	{
		"level": 4, "name": "Адский огонь",
		"damage": 70.0, "cost": 5000,
		"color": Color(0.8, 0.0, 0.0),
		"description": "Тёмное пламя ада",
		"radius": 22.0, "speed": 440.0, "cooldown": 1.7
	},
]

func get_fire_magic() -> Dictionary:
	if fire_magic_level == 0:
		return fire_magic_levels[0]
	return fire_magic_levels[fire_magic_level]

func can_upgrade_fire() -> bool:
	return fire_magic_level < fire_magic_levels.size() - 1

func upgrade_fire_magic() -> bool:
	if fire_magic_level == 0:
		print("❄️ Магия огня не продаётся! Выполни квест 'Осмотреть Древо'")
		return false
	if not can_upgrade_fire():
		print("🔥 Магия огня максимального уровня!")
		return false
	var next_level = fire_magic_level + 1
	var cost = fire_magic_levels[next_level]["cost"]
	if spend_exp(cost):
		fire_magic_level = next_level
		SaveManager.game_data.stats.fire_magic_level = fire_magic_level
		print("🔥 Магия огня улучшена до уровня:", fire_magic_level)
		emit_signal("fire_magic_upgraded", fire_magic_level)
		return true
	print("❌ Не хватает EXP! Нужно:", cost)
	return false

func unlock_fire_magic() -> void:
	if fire_magic_level == 0:
		fire_magic_level = 1
		SaveManager.game_data.stats.fire_magic_level = fire_magic_level
		print("🔥 Магия огня открыта через квест!")
		emit_signal("fire_magic_upgraded", fire_magic_level)

# ─── МАГИЯ ВОДЫ ──────────────────────────────────────────
var water_magic_unlocked: bool = false
var water_magic_level: int = 0
signal water_magic_unlocked_signal()
signal water_magic_upgraded(new_level: int)

var water_magic_levels: Array = [
	{
		"level": 0, "name": "Не получена",
		"damage": 0.0, "cost": 0,
		"color": Color(0.3, 0.6, 1.0),
		"description": "Выпадает с водных мобов",
		"radius": 0.0, "speed": 0.0, "cooldown": 1.8
	},
	{
		"level": 1, "name": "Водяной шар",
		"damage": 15.0, "cost": 0,
		"color": Color(0.2, 0.7, 1.0),
		"description": "Водяной снаряд",
		"radius": 8.0, "speed": 240.0, "cooldown": 1.5
	},
	{
		"level": 2, "name": "Водяной шар II",
		"damage": 30.0, "cost": 2000,
		"color": Color(0.0, 0.5, 1.0),
		"description": "Мощный поток воды",
		"radius": 13.0, "speed": 300.0, "cooldown": 3.0
	},
	{
		"level": 3, "name": "Водяной шар III",
		"damage": 55.0, "cost": 4000,
		"color": Color(0.0, 0.3, 0.9),
		"description": "Волна цунами",
		"radius": 18.0, "speed": 360.0, "cooldown": 1.0
	},
	{
		"level": 4, "name": "Океанская мощь",
		"damage": 90.0, "cost": 7000,
		"color": Color(0.0, 0.1, 0.8),
		"description": "Сила древнего океана",
		"radius": 25.0, "speed": 420.0, "cooldown": 0.0
	},
]

func get_water_magic() -> Dictionary:
	return water_magic_levels[max(water_magic_level, 0)]

func can_upgrade_water() -> bool:
	return water_magic_level < water_magic_levels.size() - 1

func unlock_water_magic() -> void:
	if water_magic_unlocked:
		return
	water_magic_unlocked = true
	water_magic_level = 1
	SaveManager.game_data.stats.water_magic_unlocked = water_magic_unlocked
	SaveManager.game_data.stats.water_magic_level = water_magic_level
	print("💧 Магия воды получена!")
	emit_signal("water_magic_unlocked_signal")
	emit_signal("water_magic_upgraded", water_magic_level)

func upgrade_water_magic() -> bool:
	if not water_magic_unlocked:
		return false
	if not can_upgrade_water():
		print("💧 Магия воды максимального уровня!")
		return false
	var next_level = water_magic_level + 1
	var cost = water_magic_levels[next_level]["cost"]
	if spend_exp(cost):
		water_magic_level = next_level
		SaveManager.game_data.stats.water_magic_level = water_magic_level
		print("💧 Магия воды улучшена до уровня:", water_magic_level)
		emit_signal("water_magic_upgraded", water_magic_level)
		return true
	print("❌ Не хватает EXP! Нужно:", cost)
	return false

# ─── МАГИЯ ЛЬДА ──────────────────────────────────────────
var ice_magic_unlocked: bool = false
var ice_magic_level: int = 0
signal ice_magic_upgraded(new_level: int)

var ice_magic_levels: Array = [
	{
		"level": 0, "name": "Не получена",
		"damage": 0.0, "cost": 0,
		"color": Color(0.5, 0.5, 0.5),
		"description": "Выпадает с ледяных слизей",
		"radius": 0.0, "speed": 0.0, "cooldown": 0.0
	},
	{
		"level": 1, "name": "Ледяной осколок",
		"damage": 18.0, "cost": 0,
		"color": Color(0.7, 0.95, 1.0),
		"description": "Острый ледяной снаряд",
		"radius": 6.0, "speed": 350.0, "cooldown": 1.8
	},
	{
		"level": 2, "name": "Ледяная глыба",
		"damage": 35.0, "cost": 1800,
		"color": Color(0.5, 0.85, 1.0),
		"description": "Замедляет врагов",
		"radius": 12.0, "speed": 280.0, "cooldown": 2.2
	},
	{
		"level": 3, "name": "Ледяной шторм",
		"damage": 60.0, "cost": 3500,
		"color": Color(0.3, 0.75, 1.0),
		"description": "Три осколка веером",
		"radius": 9.0, "speed": 320.0, "cooldown": 2.5
	},
	{
		"level": 4, "name": "Абсолютный ноль",
		"damage": 95.0, "cost": 6000,
		"color": Color(0.1, 0.6, 1.0),
		"description": "Замораживает на месте",
		"radius": 16.0, "speed": 260.0, "cooldown": 4.0
	},
]

func get_ice_magic() -> Dictionary:
	if ice_magic_level == 0:
		return ice_magic_levels[0]
	return ice_magic_levels[ice_magic_level]

func can_upgrade_ice() -> bool:
	return ice_magic_unlocked and ice_magic_level < ice_magic_levels.size() - 1

func unlock_ice_magic() -> void:
	if ice_magic_unlocked:
		return
	ice_magic_unlocked = true
	ice_magic_level = 1
	SaveManager.game_data.stats.ice_magic_unlocked = ice_magic_unlocked
	SaveManager.game_data.stats.ice_magic_level = ice_magic_level
	print("❄️ Магия льда получена! Уровень 1")
	emit_signal("ice_magic_upgraded", ice_magic_level)

func upgrade_ice_magic() -> bool:
	if not ice_magic_unlocked:
		print("❄️ Магия льда ещё не получена! Убей ледяную слизь!")
		return false
	if not can_upgrade_ice():
		print("❄️ Магия льда максимального уровня!")
		return false
	var next_level = ice_magic_level + 1
	var cost = ice_magic_levels[next_level]["cost"]
	if spend_exp(cost):
		ice_magic_level = next_level
		SaveManager.game_data.stats.ice_magic_level = ice_magic_level
		print("❄️ Магия льда улучшена до уровня:", ice_magic_level)
		emit_signal("ice_magic_upgraded", ice_magic_level)
		return true
	print("❌ Не хватает EXP! Нужно:", cost)
	return false

# ─── МАГИЯ КРОВИ (ВЫПАДАЕТ С БОССА ВАМПИРОВ) ────────────
var blood_magic_unlocked: bool = false
var blood_magic_level: int = 1
signal blood_magic_upgraded(new_level: int)

var blood_magic_levels: Array = [
	{
		"level": 1, "name": "Кровавый шар",
		"damage": 20.0, "cost": 0,
		"color": Color(0.8, 0.0, 0.0),
		"description": "Сгусток крови",
		"radius": 8.0, "speed": 240.0, "cooldown": 1.8
	},
	{
		"level": 2, "name": "Кровавое копьё",
		"damage": 40.0, "cost": 4500,
		"color": Color(0.7, 0.0, 0.0),
		"description": "Пробивает врагов",
		"radius": 12.0, "speed": 340.0, "cooldown": 1.5
	},
	{
		"level": 3, "name": "Кровавый взрыв",
		"damage": 70.0, "cost": 6500,
		"color": Color(0.6, 0.0, 0.0),
		"description": "Взрыв крови",
		"radius": 18.0, "speed": 260.0, "cooldown": 2.5
	},
	{
		"level": 4, "name": "Багровая смерть",
		"damage": 120.0, "cost": 10000,
		"color": Color(0.4, 0.0, 0.0),
		"description": "Древняя магия крови",
		"radius": 24.0, "speed": 420.0, "cooldown": 3.5
	},
]

func get_blood_magic() -> Dictionary:
	return blood_magic_levels[blood_magic_level - 1]

func can_upgrade_blood() -> bool:
	return blood_magic_unlocked and blood_magic_level < blood_magic_levels.size()

func unlock_blood_magic() -> void:
	if blood_magic_unlocked:
		return
	blood_magic_unlocked = true
	blood_magic_level = 1
	SaveManager.game_data.stats.blood_magic_unlocked = blood_magic_unlocked
	SaveManager.game_data.stats.blood_magic_level = blood_magic_level
	print("🩸 Магия крови получена от босса вампиров!")
	emit_signal("blood_magic_upgraded", blood_magic_level)

func upgrade_blood_magic() -> bool:
	if not blood_magic_unlocked:
		print("🩸 Магия крови ещё не получена! Победи босса вампиров!")
		return false
	if not can_upgrade_blood():
		print("🩸 Магия крови максимального уровня!")
		return false
	var next_level = blood_magic_level + 1
	var cost = blood_magic_levels[next_level - 1]["cost"]
	if spend_exp(cost):
		blood_magic_level = next_level
		SaveManager.game_data.stats.blood_magic_level = blood_magic_level
		print("🩸 Магия крови улучшена до уровня:", blood_magic_level)
		emit_signal("blood_magic_upgraded", blood_magic_level)
		return true
	print("❌ Не хватает EXP! Нужно:", cost)
	return false

# ─── МАГИЯ ЛЕЧЕНИЯ ───────────────────────────────────────
var heal_magic_unlocked: bool = false
var heal_magic_level: int = 0
var heal_magic_notification: bool = false
signal heal_magic_unlocked_signal()
signal heal_magic_upgraded(new_level: int)

var heal_magic_levels: Array = [
	{
		"level": 0, "name": "Не получена",
		"heal_amount": 0, "cost": 0,
		"color": Color(0.5, 0.5, 0.5),
		"description": "Найди пропавшую кошку",
		"cooldown": 0.0
	},
	{
		"level": 1, "name": "Малая регенерация",
		"heal_amount": 20, "cost": 0,
		"color": Color(0.2, 1.0, 0.3),
		"description": "Восстанавливает 20 HP",
		"cooldown": 9.0
	},
	{
		"level": 2, "name": "Средняя регенерация",
		"heal_amount": 40, "cost": 300,
		"color": Color(0.3, 1.0, 0.5),
		"description": "Восстанавливает 40 HP",
		"cooldown": 7.0
	},
	{
		"level": 3, "name": "Сильная регенерация",
		"heal_amount": 65, "cost": 4000,
		"color": Color(0.4, 1.0, 0.6),
		"description": "Восстанавливает 65 HP",
		"cooldown": 5.5
	},
	{
		"level": 4, "name": "Божественное исцеление",
		"heal_amount": 99, "cost": 12650,
		"color": Color(0.6, 1.0, 0.8),
		"description": "Восстанавливает 99 HP",
		"cooldown": 6.0
	},
]

func unlock_heal_magic() -> void:
	if heal_magic_unlocked:
		return
	heal_magic_unlocked = true
	heal_magic_level = 1
	heal_magic_notification = true
	SaveManager.game_data.stats.heal_magic_unlocked = heal_magic_unlocked
	SaveManager.game_data.stats.heal_magic_level = heal_magic_level
	print("💚 Магия лечения получена! Уровень 1")
	emit_signal("heal_magic_unlocked_signal")
	emit_signal("heal_magic_upgraded", heal_magic_level)
	_update_player_max_health()

func mark_heal_notification_seen() -> void:
	heal_magic_notification = false

func get_heal_magic() -> Dictionary:
	return heal_magic_levels[heal_magic_level]

func can_upgrade_heal() -> bool:
	return heal_magic_level < heal_magic_levels.size() - 1

func upgrade_heal_magic() -> bool:
	if not heal_magic_unlocked:
		return false
	if not can_upgrade_heal():
		print("💚 Магия лечения максимального уровня!")
		return false
	var next_level = heal_magic_level + 1
	var cost = heal_magic_levels[next_level]["cost"]
	if spend_exp(cost):
		heal_magic_level = next_level
		SaveManager.game_data.stats.heal_magic_level = heal_magic_level
		print("💚 Магия лечения улучшена до уровня:", heal_magic_level)
		emit_signal("heal_magic_upgraded", heal_magic_level)
		_update_player_max_health()
		return true
	print("❌ Не хватает EXP! Нужно:", cost)
	return false

func _update_player_max_health() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var new_max_health = get_health_from_heal_level()
		player.update_max_health(new_max_health)

# ─── КВЕСТЫ ──────────────────────────────────────────────
enum QuestState { NOT_TAKEN, ACTIVE, COMPLETED, HANDED_IN }
signal quest_updated()

var quest_kill_boars: QuestState = QuestState.NOT_TAKEN
var boars_killed: int = 0
var boars_needed: int = 10

var quest_cat: QuestState = QuestState.NOT_TAKEN
var cat_found: bool = false

var quest_vampire: QuestState = QuestState.NOT_TAKEN
var goblins_killed: int = 0
var goblins_needed: int = 10

var quest_tree_inspect: QuestState = QuestState.NOT_TAKEN
var tree_inspected: bool = false

# ─── КВЕСТ: КАБАНЫ ───────────────────────────────────────
func start_quest_kill_boars() -> void:
	if quest_kill_boars != QuestState.NOT_TAKEN:
		return
	quest_kill_boars = QuestState.ACTIVE
	boars_killed = 0
	SaveManager.game_data.quests.quest_kill_boars.state = quest_kill_boars
	SaveManager.game_data.quests.quest_kill_boars.progress = boars_killed
	print("📜 Квест начат: Убей 10 кабанов!")
	emit_signal("quest_updated")

func register_boar_kill() -> void:
	if quest_kill_boars != QuestState.ACTIVE:
		return
	boars_killed += 1
	SaveManager.game_data.quests.quest_kill_boars.progress = boars_killed
	print("🐗 Кабанов убито:", boars_killed, "/", boars_needed)
	emit_signal("quest_updated")
	if boars_killed >= boars_needed:
		quest_kill_boars = QuestState.COMPLETED
		SaveManager.game_data.quests.quest_kill_boars.state = quest_kill_boars
		emit_signal("quest_updated")

func hand_in_quest_kill_boars() -> bool:
	if quest_kill_boars != QuestState.COMPLETED:
		return false
	quest_kill_boars = QuestState.HANDED_IN
	SaveManager.game_data.quests.quest_kill_boars.state = quest_kill_boars
	add_exp(70)
	emit_signal("quest_updated")
	if quest_cat == QuestState.NOT_TAKEN:
		start_quest_cat()
	update_save_data()
	return true

func abandon_quest_kill_boars() -> void:
	quest_kill_boars = QuestState.NOT_TAKEN
	boars_killed = 0
	emit_signal("quest_updated")

# ─── КВЕСТ: КОШКА ────────────────────────────────────────
func start_quest_cat() -> void:
	if quest_cat != QuestState.NOT_TAKEN:
		return
	quest_cat = QuestState.ACTIVE
	cat_found = false
	SaveManager.game_data.quests.cat_quest.state = quest_cat

	emit_signal("quest_updated")

func find_cat() -> void:
	if quest_cat != QuestState.ACTIVE:
		return
	cat_found = true
	quest_cat = QuestState.COMPLETED
	SaveManager.game_data.quests.cat_quest.state = quest_cat
	SaveManager.game_data.quests.cat_quest.progress = cat_found
	emit_signal("quest_updated")

func hand_in_quest_cat() -> bool:
	if quest_cat != QuestState.COMPLETED:
		return false
	quest_cat = QuestState.HANDED_IN
	SaveManager.game_data.quests.cat_quest.state = quest_cat
	unlock_heal_magic()
	emit_signal("quest_updated")
	update_save_data()
	return true

# ─── КВЕСТ: ВАМПИР ───────────────────────────────────────
var tree_intro_shown: bool = false
var monster_encounter_triggered: bool = false
var tree_heart_stolen: bool = false
var vampire_spawned: bool = false
var second_location_unlocked: bool = false

func start_vampire_quest() -> void:
	if quest_vampire != QuestState.NOT_TAKEN:
		return
	quest_vampire = QuestState.ACTIVE
	goblins_killed = 0
	SaveManager.game_data.quests.quest_vampire.state = quest_vampire
	SaveManager.game_data.quests.quest_vampire.progress = goblins_killed
	emit_signal("quest_updated")

func register_goblin_kill() -> void:
	if quest_vampire != QuestState.ACTIVE:
		return
	goblins_killed += 1
	SaveManager.game_data.quests.quest_vampire.progress = goblins_killed
	emit_signal("quest_updated")
	if goblins_killed >= goblins_needed:
		quest_vampire = QuestState.COMPLETED
		second_location_unlocked = true
		SaveManager.game_data.quests.quest_vampire.state = quest_vampire
		SaveManager.game_data.flags.second_location_unlocked = second_location_unlocked
		emit_signal("quest_updated")

func hand_in_vampire_quest() -> bool:
	if quest_vampire != QuestState.COMPLETED:
		return false
	quest_vampire = QuestState.HANDED_IN
	vampire_spawned = false
	SaveManager.game_data.quests.quest_vampire.state = quest_vampire
	add_exp(120)
	emit_signal("quest_updated")
	return true

# ─── КВЕСТ: ОСМОТР ДЕРЕВА ────────────────────────────────
func start_quest_tree_inspect() -> void:
	if quest_tree_inspect != QuestState.NOT_TAKEN:
		return
	quest_tree_inspect = QuestState.ACTIVE
	SaveManager.game_data.quests.quest_tree_inspect.state = quest_tree_inspect
	emit_signal("quest_updated")

func complete_tree_inspect() -> void:
	if quest_tree_inspect != QuestState.ACTIVE:
		return
	quest_tree_inspect = QuestState.COMPLETED
	tree_inspected = true
	SaveManager.game_data.quests.quest_tree_inspect.state = quest_tree_inspect
	SaveManager.game_data.quests.quest_tree_inspect.progress = tree_inspected
	unlock_fire_magic()
	emit_signal("quest_updated")

# ─── КОНЦОВКА ────────────────────────────────────────────
var heart_returned: bool = false
var ending_triggered: bool = false
enum Ending { NONE, BAD, GOOD }
var current_ending: Ending = Ending.NONE
signal ending_triggered_signal(ending: Ending)

# ─── ФИНАЛЬНЫЙ БОСС ──────────────────────────────────────
var final_boss_defeated: bool = false
signal final_boss_defeated_changed  # 👈 ДОБАВЬ ЭТУ СТРОКУ

func set_final_boss_defeated(value: bool) -> void:
	final_boss_defeated = value
	emit_signal("final_boss_defeated_changed")
	print("👑 Финальный босс побеждён! Сигнал отправлен.")

# ─── СОХРАНЕНИЕ / ЗАГРУЗКА ───────────────────────────────
func update_save_data() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		print("⚠️ Игрок не найден для сохранения!")
		return
	SaveManager.game_data.player_pos = {"x": player.position.x, "y": player.position.y}
	SaveManager.game_data.current_scene = get_tree().current_scene.scene_file_path
	SaveManager.game_data.stats.exp = exp
	SaveManager.game_data.stats.current_health = player.current_health
	SaveManager.save_game()

func apply_load_data() -> void:
	SaveManager.load_game()
	var data = SaveManager.game_data
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.position = Vector2(data.player_pos.x, data.player_pos.y)
		player.current_health = data.stats.current_health
		if player.hp_bar:
			player.hp_bar.value = player.current_health
			player._update_hp_label()
	exp = data.stats.exp
	emit_signal("exp_changed", exp)
	
	sword_level = data.stats.sword_level
	sword_lvl3_dropped = data.stats.sword_lvl3_dropped
	fire_sword_unlocked = data.stats.fire_sword_unlocked
	fire_sword_level = data.stats.fire_sword_level
	
	fire_magic_level = data.stats.fire_magic_level
	
	water_magic_level = data.stats.water_magic_level
	water_magic_unlocked = data.stats.water_magic_unlocked
	
	ice_magic_unlocked = data.stats.ice_magic_unlocked
	ice_magic_level = data.stats.ice_magic_level
	
	blood_magic_unlocked = data.stats.blood_magic_unlocked
	blood_magic_level = data.stats.blood_magic_level
	
	heal_magic_unlocked = data.stats.heal_magic_unlocked
	heal_magic_level = data.stats.heal_magic_level
	
	if data.quests.has("quest_kill_boars"):
		quest_kill_boars = data.quests.quest_kill_boars.state
		boars_killed = data.quests.quest_kill_boars.progress
		
	if data.quests.has("cat_quest"):
		quest_cat = data.quests.cat_quest.state
		cat_found = data.quests.cat_quest.progress
		
	if data.quests.has("quest_vampire"):
		quest_vampire = data.quests.quest_vampire.state
		goblins_killed = data.quests.quest_vampire.progress
		
	if data.quests.has("quest_tree_inspect"):
		quest_tree_inspect = data.quests.quest_tree_inspect.state
		tree_inspected = data.quests.quest_tree_inspect.progress
		
	tree_intro_shown = data.flags.tree_intro_shown
	monster_encounter_triggered = data.flags.monster_encounter_triggered
	tree_heart_stolen = data.flags.tree_heart_stolen
	vampire_spawned = data.flags.vampire_spawned
	second_location_unlocked = data.flags.second_location_unlocked
