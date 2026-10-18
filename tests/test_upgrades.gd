extends GameTest


## Starts a match and drives the fortress to the first stop.
func _match_at_stop() -> Node:
	var m := await start_match()
	var follower: RouteFollower = m.get_node("Fortress/RouteFollower")
	follower.base_speed = 300.0
	for i in 300:
		await frames(1)
		if follower.is_stopped:
			break
	check(follower.is_stopped, "fortress reaches the stop")
	return m


func test_tier_upgrade_only_at_stop_and_keeps_damage() -> void:
	var m := await start_match()
	var fortress: Fortress = m.get_node("Fortress")
	fortress.storage.add_all({&"stone": 20, &"wood": 10})
	check(not m.request_tier_upgrade(), "no upgrades while moving")

	m = await _match_at_stop()
	fortress = m.get_node("Fortress")
	fortress.storage.add_all({&"stone": 12, &"wood": 6})
	fortress.health.apply_damage(100.0)
	var health_before := fortress.health.current  # also includes the bomb on the way
	check(m.request_tier_upgrade(), "upgrade succeeds at the stop")
	check(fortress.get_tier().id == &"stone", "body is now stone")
	check(fortress.health.max_health == 800.0, "stone max health")
	check(fortress.health.current == health_before + 300.0, "damage taken is kept, got %.0f" % fortress.health.current)
	check(fortress.storage.amounts == {&"stone": 2, &"wood": 1}, "cost spent, left %s" % fortress.storage.amounts)
	check(not m.request_tier_upgrade(), "no tier above stone yet")


func test_tier_upgrade_needs_full_cost() -> void:
	var m := await _match_at_stop()
	var fortress: Fortress = m.get_node("Fortress")
	fortress.storage.add_all({&"stone": 9, &"wood": 5})
	check(not m.request_tier_upgrade(), "one stone short fails")
	check(fortress.get_tier().id == &"wood", "still wood")
	check(fortress.storage.amounts == {&"stone": 9, &"wood": 5}, "nothing spent on failure")


func test_towers_fill_four_slots() -> void:
	var m := await _match_at_stop()
	var fortress: Fortress = m.get_node("Fortress")
	fortress.storage.add_all({&"wood": 30, &"stone": 20})
	for i in 4:
		check(m.request_build_tower(), "tower %d builds" % (i + 1))
	check(fortress.free_tower_slots() == 0, "all slots used")
	check(not m.request_build_tower(), "no fifth tower")
	check(fortress.storage.amounts == {&"wood": 6, &"stone": 4}, "4 towers cost 24 wood 16 stone")


func test_tower_kills_enemy_without_player() -> void:
	var m := await _match_at_stop()
	var fortress: Fortress = m.get_node("Fortress")
	fortress.storage.add_all(fortress.tower_cost)
	check(m.request_build_tower(), "tower builds")
	m.get_node("Warrior").global_position = fortress.global_position + Vector3(80, 0.1, 0)
	var enemy: Enemy = m.get_node("Spawner").spawn_one()
	enemy.global_position = fortress.global_position + Vector3(10, 0, 0)
	await seconds(4.0)
	check(not is_instance_valid(enemy), "tower shoots the enemy down")


func test_panel_shows_at_stop_and_buys() -> void:
	var m := await start_match()
	var panel: UpgradePanel = m.get_node("UI/UpgradePanel")
	check(not panel.visible, "panel hidden while moving")
	m = await _match_at_stop()
	panel = m.get_node("UI/UpgradePanel")
	var fortress: Fortress = m.get_node("Fortress")
	check(panel.visible, "panel shown at the stop")
	check(panel._tower_button.disabled, "tower button disabled without resources")
	fortress.storage.add_all(fortress.tower_cost)
	check(not panel._tower_button.disabled, "tower button enabled once affordable")
	panel._tower_button.pressed.emit()
	check(fortress.free_tower_slots() == 3, "pressing the button builds a tower")
	panel.depart_requested.emit()
	await frames(1)
	check(not panel.visible, "panel hides on departure")
