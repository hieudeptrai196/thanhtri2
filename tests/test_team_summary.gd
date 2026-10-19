extends GameTest
## M2.5: end-of-run summary by role — who built, hauled, killed and revived the most.

const ENGINEER := preload("res://classes/types/engineer.tres")
const BARRICADE := preload("res://structures/types/barricade.tres")


func _team_texts(m: Match) -> String:
	var texts := PackedStringArray()
	for cell: Label in m._result_screen.get_node("%Team").get_children():
		if not cell.is_queued_for_deletion():
			texts.append(cell.text)
	return " | ".join(texts)


func test_best_per_category() -> void:
	var stats := TeamStats.new()
	check(stats.best(&"kills") == 0, "nobody before anything happens")
	stats.add(5, &"kills", 3)
	stats.add(9, &"kills", 7)
	stats.add(9, &"haul", 2)
	stats.add(5, &"haul", 2)
	check(stats.best(&"kills") == 9, "most kills")
	check(stats.best(&"haul") == 5, "a tie goes to who joined first")
	check(stats.best(&"revives") == 0, "nobody revived")
	var copy := TeamStats.new()
	copy.apply_net_state(stats.net_state())
	check(copy.value(9, &"kills") == 7.0 and copy.order(5) == 1, "survives the trip over the network")


func test_hammering_and_hauling_are_counted() -> void:
	var m: Match = await start_match()
	var fortress: Fortress = m.get_node("Fortress")
	fortress.follower.base_speed = 0.0
	fortress.storage.add_all({&"wood": 50})
	clear_random_bombs(m)
	var warrior: Warrior = m.get_node("Warrior")
	var spot := fortress.global_position + Vector3(25, 0, 25)
	warrior.global_position = spot + Vector3(-1.5, 0.1, 0)
	await frames(2)
	(m.get_node("Structures") as StructureNetwork).place_blueprint(BARRICADE, spot)
	Input.action_press(&"interact")
	await seconds(1.0)
	Input.action_release(&"interact")
	check_near(m.team_stats.value(1, &"build"), 1.0, 0.1, "about a second of hammering")
	warrior.inventory.add(&"wood", 4)
	warrior.inventory.add(&"coal", 2)
	warrior.global_position = fortress.global_position + Vector3(6, 0.1, 0)
	await frames(3)
	check(m.team_stats.value(1, &"haul") == 6.0, "six units brought home")


func test_kills_go_to_the_hand_that_finished_them() -> void:
	var m: Match = await start_match()
	var fortress: Fortress = m.get_node("Fortress")
	fortress.follower.base_speed = 0.0
	var warrior: Warrior = m.get_node("Warrior")
	var spawner: Spawner = m.get_node("Spawner")
	var mine := spawner.spawn_one()
	mine.get_node("Hurtbox").take_hit(1e6, warrior)
	await frames(2)
	check(m.team_stats.value(1, &"kills") == 1.0, "the warrior's kill")
	var turret := (m.get_node("Structures") as StructureNetwork).place(preload("res://structures/types/crossbow_turret.tres"),
		fortress.global_position + Vector3(25, 0, 25))
	spawner.spawn_one().get_node("Hurtbox").take_hit(1e6, turret)
	await frames(2)
	check(m.team_stats.value(1, &"kills") == 1.0, "a turret's kill is nobody's")
	warrior.global_position = fortress.ladder_point()
	await frames(2)
	fortress.try_man_crossbow(warrior)
	spawner.spawn_one().get_node("Hurtbox").take_hit(1e6, fortress)
	await frames(2)
	check(m.team_stats.value(1, &"kills") == 2.0, "the manned crossbow's kill goes to its gunner")


func test_reviving_is_counted() -> void:
	var m: Match = await start_match()
	var fortress: Fortress = m.get_node("Fortress")
	fortress.follower.base_speed = 0.0
	var down: Warrior = m.get_node("Warrior")
	var helper: Warrior = m.spawn_player(2)
	helper.input.remote = true
	down.global_position = fortress.global_position + Vector3(0, 0.1, 25)
	helper.global_position = down.global_position + Vector3(1.2, 0, 0)
	await frames(2)
	down.health.apply_damage(9999.0)
	await frames(1)
	helper.input.apply_remote_state({"interact": true})
	await wait_until(func() -> bool: return down.is_alive, roundi(down.revive_time * 60) + 30)
	check(m.team_stats.value(2, &"revives") == 1.0, "one revive for the helper")
	check(m.team_stats.value(1, &"revives") == 0.0, "none for the one helped up")


func test_result_shows_mvps_in_coop() -> void:
	var m: Match = await start_match()
	var mate: Warrior = m.spawn_player(2, ENGINEER)
	mate.input.remote = true
	m.team_stats.add(2, &"build", 12.4)
	m.team_stats.add(1, &"kills", 9)
	m.get_node("Fortress").health.apply_damage(1e6)
	await frames(2)
	var texts := _team_texts(m)
	check("Thợ xây cừ nhất" in texts and "Công binh — gõ búa 12 giây" in texts, "best builder by class name: %s" % texts)
	check("Người chơi 1 (bạn) — hạ 9 quái" in texts, "this machine's player marked: %s" % texts)
	check(not "Cứu người nhiều nhất" in texts, "no row for what nobody did")


func test_result_shows_own_share_solo() -> void:
	var m: Match = await start_match()
	m.team_stats.add(1, &"kills", 4)
	m.get_node("Fortress").health.apply_damage(1e6)
	await frames(2)
	check("tự tay hạ 4 quái" in _team_texts(m), "solo: own numbers (%s)" % _team_texts(m))


func test_client_gets_the_summary() -> void:
	var matches := await start_net_match(1, 1, 24870)
	var host: Match = matches[0]
	var client: Match = matches[1]
	var client_peer := client.multiplayer.get_unique_id()
	host.team_stats.add(client_peer, &"haul", 30)
	host.get_node("Fortress").health.apply_damage(1e6)
	check(await wait_until(func() -> bool: return client.result != Match.Result.NONE, 120), "client sees the end")
	check(client.team_stats.value(client_peer, &"haul") == 30.0, "with the host's numbers")
	check("(bạn) — mang về 30 tài nguyên" in _team_texts(client), "the client is marked as itself: %s" % _team_texts(client))
