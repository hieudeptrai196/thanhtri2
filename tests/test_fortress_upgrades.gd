extends GameTest

const CROSSBOW := preload("res://fortress/upgrades/crossbow.tres")
const OIL := preload("res://fortress/upgrades/boiling_oil.tres")
const FURNACE := preload("res://fortress/upgrades/furnace.tres")
const SHIELD := preload("res://fortress/upgrades/shield.tres")


func _match_at_stop() -> Node:
	var m := await start_match()
	var follower: RouteFollower = m.get_node("Fortress/RouteFollower")
	follower.base_speed = 300.0
	for i in 300:
		await frames(1)
		if follower.is_stopped:
			break
	check(follower.is_stopped, "fortress reaches the stop")
	m.get_node("Warrior").global_position = m.get_node("Fortress").global_position + Vector3(60, 0.1, 0)
	return m


## A parked fortress with its own weapons quiet, so a test sees one effect at a time.
func _quiet_fortress(m: Node) -> Fortress:
	var fortress: Fortress = m.get_node("Fortress")
	fortress.follower.base_speed = 0.0
	fortress.crossbow.enabled = false
	fortress.thorns_damage = 0.0
	fortress.fuel_per_second = 0.0
	return fortress


func _enemy_at_walls(m: Node, health_multiplier: float = 1.0) -> Enemy:
	var enemy: Enemy = m.get_node("Spawner").spawn_one()
	enemy.move_speed = 0.0
	enemy.damage = 0.0
	enemy.global_position = m.get_node("Fortress").global_position + Vector3(6.5, 0, 0)
	enemy.apply_scaling(health_multiplier, 1.0)
	return enemy


func test_crossbow_levels_cost_mixed_resources() -> void:
	var m := await start_match()
	var fortress: Fortress = m.get_node("Fortress")
	fortress.storage.add_all({&"wood": 100, &"bronze": 100})
	check(not m.request_fortress_upgrade(CROSSBOW), "no upgrades while moving")

	m = await _match_at_stop()
	fortress = m.get_node("Fortress")
	fortress.storage.add_all({&"wood": 10, &"bronze": 3})
	check(m.request_fortress_upgrade(CROSSBOW), "level 1 bought at the stop")
	check(fortress.storage.total() == 0, "costs wood and bronze together")
	check(fortress.crossbow.damage == 9.0 and fortress.crossbow.interval == 1.0 and fortress.crossbow.range_radius == 12.0,
		"crossbow hits harder, faster and farther")
	check(not m.request_fortress_upgrade(CROSSBOW), "level 2 needs more resources")
	fortress.storage.add_all({&"wood": 100, &"bronze": 100})
	check(m.request_fortress_upgrade(CROSSBOW) and m.request_fortress_upgrade(CROSSBOW), "levels 2 and 3")
	check(fortress.upgrade_level(&"crossbow") == 3, "at level 3")
	check(not m.request_fortress_upgrade(CROSSBOW), "no level beyond the last")


func test_boiling_oil_pours_when_health_drops_a_step() -> void:
	var m := await _match_at_stop()
	var fortress := _quiet_fortress(m)
	fortress.storage.add_all(OIL.costs[0])
	check(m.request_fortress_upgrade(OIL), "boiling oil bought")
	var enemy := _enemy_at_walls(m, 3.0)
	await frames(3)
	var before: float = enemy.get_node("Health").current
	fortress.health.apply_damage(fortress.health.max_health * 0.1)
	await frames(3)
	check(enemy.get_node("Health").current == before, "a small loss pours nothing")
	fortress.health.apply_damage(fortress.health.max_health * 0.15)
	await frames(3)
	check_near(before - enemy.get_node("Health").current, fortress.oil_damage, 0.01, "crossing 20% lost pours oil on enemies at the walls")


func test_furnace_burns_coal_to_hit_enemies_at_the_walls() -> void:
	var m := await _match_at_stop()
	var fortress := _quiet_fortress(m)
	fortress.storage.add_all(FURNACE.costs[0])
	check(m.request_fortress_upgrade(FURNACE), "furnace bought")
	fortress.storage.add(&"coal", 5)
	await seconds(3.0)
	check(fortress.storage.get_amount(&"coal") == 5, "no enemy, no coal burned")
	var enemy := _enemy_at_walls(m, 3.0)
	await seconds(2.5)
	check(fortress.storage.get_amount(&"coal") < 5, "a burst burns coal")
	check(enemy.get_node("Health").current <= enemy.get_node("Health").max_health - fortress.furnace_damage, "and burns the enemy")


func test_shield_soaks_damage_and_regenerates() -> void:
	var m := await _match_at_stop()
	var fortress := _quiet_fortress(m)
	fortress.storage.add_all(SHIELD.costs[0])
	check(m.request_fortress_upgrade(SHIELD), "shield bought")
	check(fortress.health.shield == 100.0, "a new shield starts full")
	var hp := fortress.health.current
	fortress.get_node("Hurtbox").take_hit(60.0, null)
	check(fortress.health.current == hp and fortress.health.shield == 40.0, "the shield takes the hit first")
	fortress.get_node("Hurtbox").take_hit(60.0, null)
	check(fortress.health.shield == 0.0 and fortress.health.current == hp - 20.0, "overflow reaches the walls")
	await seconds(fortress.shield_regen_delay + 1.0)
	check(fortress.health.shield > 0.0, "the shield regenerates after a quiet moment")


func test_panel_lists_fortress_upgrades_and_buys() -> void:
	var m := await _match_at_stop()
	var panel: UpgradePanel = m.get_node("UI/UpgradePanel")
	var fortress: Fortress = m.get_node("Fortress")
	check(panel._upgrade_buttons.size() == FortressUpgrades.ALL.size(), "one button per upgrade")
	var button: Button = panel._upgrade_buttons[CROSSBOW]
	check(button.disabled, "disabled without resources")
	fortress.storage.add_all(CROSSBOW.costs[0])
	check(not button.disabled, "enabled once affordable")
	button.pressed.emit()
	check(fortress.upgrade_level(&"crossbow") == 1, "pressing buys the next level")
	check(button.text.contains("2"), "the button now offers level 2: %s" % button.text)
