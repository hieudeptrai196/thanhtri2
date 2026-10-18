extends GameTest

const WON := 1
const LOST := 2


func test_reaching_the_end_wins_and_pauses() -> void:
	var m := await start_match()
	var follower: RouteFollower = m.get_node("Fortress/RouteFollower")
	var result_screen: ResultScreen = m.get_node("UI/ResultScreen")
	check(not result_screen.visible, "no result screen during play")
	follower.base_speed = 300.0
	for i in 600:
		await frames(1)
		if follower.is_stopped:
			follower.depart()
		if m.result != 0:
			break
	check(m.result == WON, "reaching the end wins, result=%d" % m.result)
	check(tree.paused, "the world pauses on the result")
	check(result_screen.visible, "result screen is shown")
	check(not m.get_node("Spawner").active, "no more spawning after the result")


func test_fortress_destroyed_loses() -> void:
	var m := await start_match(1, true)
	var fortress: Fortress = m.get_node("Fortress")
	fortress.health.apply_damage(fortress.health.max_health)
	await frames(1)
	check(m.result == LOST, "a destroyed fortress loses, result=%d" % m.result)
	check(tree.paused, "the world pauses on the result")
	check(m.get_node("UI/ResultScreen").visible, "result screen is shown")
	check(not m.get_node("Spawner").active, "spawning stops")


func test_result_counts_kills_and_offers_restart() -> void:
	var m := await start_match()
	m.get_node("Fortress").follower.base_speed = 0.0
	var warrior: Warrior = m.get_node("Warrior")
	warrior.global_position = Vector3(40, 0.1, 0)
	var enemy: Enemy = m.get_node("Spawner").spawn_one()
	enemy.global_position = warrior.global_position + Vector3(2, 0, 3)
	await attack_until_freed(warrior, enemy)
	await frames(2)
	check(m.kills == 1, "kill is counted, got %d" % m.kills)

	var restarts := [0]
	var result_screen: ResultScreen = m.get_node("UI/ResultScreen")
	# The real handler reloads the current scene, which the test harness does not have.
	result_screen.restart_requested.disconnect(m.restart)
	result_screen.restart_requested.connect(func() -> void: restarts[0] += 1)
	m.get_node("Fortress").health.apply_damage(9999.0)
	await frames(1)
	check(result_screen.get_node("%Stats").text.contains("1"), "stats mention the kill")
	result_screen.get_node("%Restart").pressed.emit()
	check(restarts[0] == 1, "restart button asks for a restart")


func test_hud_tracks_fortress_route_and_resources() -> void:
	var m := await start_match()
	var fortress: Fortress = m.get_node("Fortress")
	fortress.follower.base_speed = 0.0
	var hud: Hud = m.get_node("UI/HUD")
	var warrior: Warrior = m.get_node("Warrior")
	fortress.health.apply_damage(120.0)
	check(hud.get_node("%FortressBar").value == 380.0, "fortress bar follows health")
	check(hud.get_node("%RouteProgress").follower == fortress.follower, "route strip follows the fortress")

	warrior.global_position = Vector3(40, 0.1, 0)
	await frames(2)
	warrior.inventory.add(&"wood", 4)
	check(hud._carried[0].type.id == &"wood" and hud._carried[0]._amount.text == "4", "carried wood shows 4")
	check(hud._carried_label.text.contains("4/20"), "carried total shows 4/20")
	fortress.storage.add(&"stone", 7)
	check(hud._stored[1]._amount.text == "7", "stored stone shows 7")


func test_hud_hints_repair_and_shows_respawn() -> void:
	var m := await start_match()
	var fortress: Fortress = m.get_node("Fortress")
	fortress.follower.base_speed = 0.0
	var hud: Hud = m.get_node("UI/HUD")
	var warrior: Warrior = m.get_node("Warrior")
	var hint: Label = hud.get_node("%RepairHint")

	warrior.global_position = fortress.global_position + Vector3(7, 0.1, 0)
	await frames(3)
	check(not hint.visible, "no repair hint while the fortress is undamaged")
	fortress.health.apply_damage(50.0)
	await frames(2)
	check(hint.visible, "repair hint shows next to a damaged fortress")
	warrior.global_position = Vector3(60, 0.1, 60)
	await frames(3)
	check(not hint.visible, "repair hint hides away from the fortress")

	check(hud.get_node("%WarriorBar").visible, "warrior bar shows while alive")
	warrior.health.apply_damage(1000.0)
	await frames(2)
	check(not hud.get_node("%WarriorBar").visible, "warrior bar hides when fallen")
	check(hud.get_node("%CenterMessage").visible, "respawn countdown shows")
	await seconds(m.respawn_delay + 0.2)
	check(not hud.get_node("%CenterMessage").visible, "countdown clears after respawn")


func test_bomb_and_stop_show_toasts() -> void:
	var m := await start_match()
	var hud: Hud = m.get_node("UI/HUD")
	var toasts := []
	m.get_node("Bombs/Bomb1").exploded.connect(func(_at: Vector3) -> void: toasts.append(hud.get_node("%Toast").text))
	var follower: RouteFollower = m.get_node("Fortress/RouteFollower")
	follower.base_speed = 60.0
	for i in 900:
		await frames(1)
		if follower.is_stopped:
			break
	await frames(1)
	check(hud.get_node("%Toast").text.contains(tr("Điểm dừng")), "stop toast shown, got '%s'" % hud.get_node("%Toast").text)
	check(toasts.size() == 1, "the bomb exploded on the way")
