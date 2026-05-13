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
		"radius": 0.0, "speed": 0.0,
		"cooldown": 0.0
	},
	{
		"level": 1, "name": "Огненный шар",
		"damage": 10.0, "cost": 0,
		"color": Color(1.0, 0.5, 0.0),
		"description": "Маленький огненный шар",
		"radius": 7.0, "speed": 260.0,
		"cooldown": 2.0
	},
	{
		"level": 2, "name": "Огненный шар II",
		"damage": 22.0, "cost": 150,
		"color": Color(1.0, 0.75, 0.0),
		"description": "Большой горящий шар",
		"radius": 11.0, "speed": 320.0,
		"cooldown": 1.7
	},
	{
		"level": 3, "name": "Огненный шар III",
		"damage": 40.0, "cost": 300,
		"color": Color(1.0, 0.25, 0.0),
		"description": "Огромный шар с искрами",
		"radius": 16.0, "speed": 380.0,
		"cooldown": 1.5
	},
	{
		"level": 4, "name": "Адский огонь",
		"damage": 70.0, "cost": 500,
		"color": Color(0.8, 0.0, 0.0),
		"description": "Тёмное пламя ада",
		"radius": 22.0, "speed": 440.0,
		"cooldown": 1.7
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
	
	# ─── АКТИВНАЯ МАГИЯ ──────────────────────────────────────
# "fire" или "water" - какая магия сейчас активна
var active_magic: String = "fire"
signal active_magic_changed(magic_type: String)

func set_active_magic(type: String) -> void:
	if type == "heal" and not heal_magic_unlocked:
		print("💚 Магия лечения ещё не открыта!")
		return
	active_magic = type
	print("✨ Активная магия:", type)
	emit_signal("active_magic_changed", type)

func get_active_magic_level() -> int:
	match active_magic:
		"fire":  return fire_magic_level
		"water": return water_magic_level
		"heal":  return heal_magic_level 
	return 0

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
		"radius": 0.0, "speed": 0.0,
		"cooldown": 1.8
	},
	{
		"level": 1, "name": "Водяной шар",
		"damage": 15.0, "cost": 0,
		"color": Color(0.2, 0.7, 1.0),
		"description": "Водяной снаряд",
		"radius": 8.0, "speed": 240.0,
		"cooldown": 1.5
	},
	{
		"level": 2, "name": "Водяной шар II",
		"damage": 30.0, "cost": 200,
		"color": Color(0.0, 0.5, 1.0),
		"description": "Мощный поток воды",
		"radius": 13.0, "speed": 300.0,
		"cooldown": 3.0
	},
	{
		"level": 3, "name": "Водяной шар III",
		"damage": 55.0, "cost": 400,
		"color": Color(0.0, 0.3, 0.9),
		"description": "Волна цунами",
		"radius": 18.0, "speed": 360.0,
		"cooldown": 1.0
	},
	{
		"level": 4, "name": "Океанская мощь",
		"damage": 90.0, "cost": 700,
		"color": Color(0.0, 0.1, 0.8),
		"description": "Сила древнего океана",
		"radius": 25.0, "speed": 420.0,
		"cooldown": 0.0
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
		print("💧 Магия воды улучшена до уровня:", water_magic_level)
		emit_signal("water_magic_upgraded", water_magic_level)
		return true
	print("❌ Не хватает EXP! Нужно:", cost)
	return false
	# ─── КВЕСТЫ ──────────────────────────────────────────────
# ─── КВЕСТЫ ──────────────────────────────────────────────
enum QuestState { NOT_TAKEN, ACTIVE, COMPLETED, HANDED_IN }

# Квест 1: Убить кабанов
var quest_kill_boars: QuestState = QuestState.NOT_TAKEN
var boars_killed: int = 0
var boars_needed: int = 10

# Квест 2: Найти кошку (открывается после квеста с кабанами)
var quest_cat: QuestState = QuestState.NOT_TAKEN
var cat_found: bool = false

signal quest_updated()

# ─── МАГИЯ ЛЕЧЕНИЯ ──────────────────────────────────────
var heal_magic_unlocked: bool = false
var heal_magic_level: int = 0

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
		"heal_amount": 25, "cost": 0,
		"color": Color(0.2, 1.0, 0.3),
		"description": "Восстанавливает 25 HP",
		"cooldown": 9.0
	},
	{
		"level": 2, "name": "Средняя регенерация",
		"heal_amount": 50, "cost": 200,
		"color": Color(0.3, 1.0, 0.5),
		"description": "Восстанавливает 50 HP",
		"cooldown": 7.0
	},
	{
		"level": 3, "name": "Сильная регенерация",
		"heal_amount": 85, "cost": 400,
		"color": Color(0.4, 1.0, 0.6),
		"description": "Восстанавливает 85 HP",
		"cooldown": 5.5
	},
	{
		"level": 4, "name": "Божественное исцеление",
		"heal_amount": 125, "cost": 650,
		"color": Color(0.6, 1.0, 0.8),
		"description": "Восстанавливает 125 HP",
		"cooldown": 6.0
	},
]

# ─── КВЕСТ: ПРОПАВШАЯ КОШКА ──────────────────────────────
func start_quest_cat() -> void:
	if quest_cat != QuestState.NOT_TAKEN:
		return
	quest_cat = QuestState.ACTIVE
	cat_found = false
	print("🐱 Квест начат: Найди пропавшую кошку!")
	emit_signal("quest_updated")

func find_cat() -> void:
	if quest_cat != QuestState.ACTIVE:
		return
	cat_found = true
	quest_cat = QuestState.COMPLETED
	print("🐱 Кошка найдена! Вернись к старейшине!")
	emit_signal("quest_updated")

func hand_in_quest_cat() -> bool:
	if quest_cat != QuestState.COMPLETED:
		return false
	quest_cat = QuestState.HANDED_IN
	
	# 🎁 Открываем магию лечения
	unlock_heal_magic()
	
	print("🐱 Квест сдан! Открыта магия лечения!")
	emit_signal("quest_updated")
	
	update_save_data()
	
	return true

# ─── МАГИЯ ЛЕЧЕНИЯ ──────────────────────────────────────

var heal_magic_notification: bool = false  # Новое уведомление о магии
func unlock_heal_magic() -> void:
	if heal_magic_unlocked:
		return
	heal_magic_unlocked = true
	heal_magic_level = 1
	heal_magic_notification = true
	print("💚 Магия лечения получена! Уровень 1")
	emit_signal("heal_magic_unlocked_signal")
	emit_signal("heal_magic_upgraded", heal_magic_level)

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
		print("💚 Магия лечения улучшена до уровня:", heal_magic_level)
		emit_signal("heal_magic_upgraded", heal_magic_level)
		return true
	print("❌ Не хватает EXP! Нужно:", cost)
	return false

# ─── КВЕСТ: КАБАНЫ ──────────────────────────────────────
func start_quest_kill_boars() -> void:
	if quest_kill_boars != QuestState.NOT_TAKEN:
		return
	quest_kill_boars = QuestState.ACTIVE
	boars_killed = 0
	print("📜 Квест начат: Убей 10 кабанов!")
	emit_signal("quest_updated")

func register_boar_kill() -> void:
	if quest_kill_boars != QuestState.ACTIVE:
		return
	boars_killed += 1
	print("🐗 Кабанов убито:", boars_killed, "/", boars_needed)
	emit_signal("quest_updated")
	if boars_killed >= boars_needed:
		quest_kill_boars = QuestState.COMPLETED
		print("✅ Квест выполнен! Вернись к старейшине!")
		emit_signal("quest_updated")

func hand_in_quest_kill_boars() -> bool:
	if quest_kill_boars != QuestState.COMPLETED:
		return false
	quest_kill_boars = QuestState.HANDED_IN
	add_exp(300)
	print("🎉 Квест сдан! +300 EXP!")
	emit_signal("quest_updated")
	
	# После сдачи квеста с кабанами открывается квест с кошкой
	if quest_cat == QuestState.NOT_TAKEN:
		start_quest_cat()
	
	update_save_data()
	
	return true
	
func update_save_data():
	var player = get_tree().get_first_node_in_group("player")
	
	SaveManager.game_data.player_pos = {"x": player.position.x, "y": player.position.y}
	SaveManager.game_data.current_scene = get_tree().current_scene.scene_file_path
	SaveManager.game_data.stats.exp = exp
	print(SaveManager.game_data.stats.exp)
	SaveManager.game_data.stats.current_health = player.current_health
	print(SaveManager.game_data.stats.current_health)
	SaveManager.game_data.stats.sword_level = sword_level
	SaveManager.game_data.stats.fire_magic_level = fire_magic_level
	SaveManager.game_data.stats.water_magic_level= water_magic_level
	SaveManager.game_data.stats.heal_magic_level= heal_magic_level
	
	SaveManager.game_data.quests.quest_kill_boars.state = quest_kill_boars
	SaveManager.game_data.quests.quest_kill_boars.progress = boars_killed
	
	SaveManager.game_data.quests.cat_quest.state = quest_cat
	SaveManager.game_data.quests.cat_quest.progress = {"cat_found": cat_found, "heal_magic_unlocked": heal_magic_unlocked}
	
	SaveManager.save_game()

func apply_load_data():
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
	fire_magic_level = data.stats.fire_magic_level
	water_magic_level = data.stats.water_magic_level
	heal_magic_level = data.stats.heal_magic_level
	
	if data.quests.has("quest_kill_boars"):
		quest_kill_boars = data.quests.quest_kill_boars.state
		boars_killed = data.quests.quest_kill_boars.progress
		
	if data.quests.has("cat_quest"):
		quest_cat = data.quests.cat_quest.state
		cat_found = data.quests.cat_quest.progress.cat_found
		heal_magic_unlocked = data.quests.cat_quest.progress.heal_magic_unlocked
