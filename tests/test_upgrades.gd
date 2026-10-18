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
	fortress.storage.add_all({&"bronze": 10, &"wood": 30})
	check(not m.request_tier_upgrade(), "no upgrades while moving")

	m = await _match_at_stop()
	fortress = m.get_node("Fortress")
	fortress.storage.add_all({&"bronze": 8, &"wood": 21})
	fortress.health.apply_damage(100.0)
	var health_before := fortress.health.current  # also includes the bomb on the way
	check(m.request_tier_upgrade(), "upgrade succeeds at the stop")
	check(fortress.get_tier().id == &"stone", "body is now stone")
	check(fortress.health.max_health == 800.0, "stone max health")
	check(fortress.health.current == health_before + 300.0, "damage taken is kept, got %.0f" % fortress.health.current)
	check(fortress.storage.amounts == {&"bronze": 2, &"wood": 1}, "cost spent, left %s" % fortress.storage.amounts)
	check(not m.request_tier_upgrade(), "no tier above stone yet")


func test_tier_upgrade_needs_full_cost() -> void:
	var m := await _match_at_stop()
	var fortress: Fortress = m.get_node("Fortress")
	fortress.storage.add_all({&"bronze": 5, &"wood": 20})
	check(not m.request_tier_upgrade(), "one bronze short fails")
	check(fortress.get_tier().id == &"wood", "still wood")
	check(fortress.storage.amounts == {&"bronze": 5, &"wood": 20}, "nothing spent on failure")


func test_panel_shows_at_stop_and_upgrades_body() -> void:
	var m := await start_match()
	var panel: UpgradePanel = m.get_node("UI/UpgradePanel")
	check(not panel.visible, "panel hidden while moving")
	m = await _match_at_stop()
	panel = m.get_node("UI/UpgradePanel")
	var fortress: Fortress = m.get_node("Fortress")
	check(panel.visible, "panel shown at the stop")
	check(panel._tier_button.disabled, "body upgrade disabled without resources")
	fortress.storage.add_all(fortress.get_next_tier().cost)
	check(not panel._tier_button.disabled, "body upgrade enabled once affordable")
	panel._tier_button.pressed.emit()
	check(fortress.get_tier().id == &"stone", "pressing the button upgrades the body")
	panel.depart_requested.emit()
	await frames(1)
	check(not panel.visible, "panel hides on departure")
