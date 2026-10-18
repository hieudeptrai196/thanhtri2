extends GameTest
## Co-op over ENet with host and client in one process (see GameTest.start_net_match).


func test_client_gets_its_own_warrior_on_both_machines() -> void:
	var matches := await start_net_match()
	var host: Match = matches[0]
	var client: Match = matches[1]
	var client_id := client.multiplayer.get_unique_id()
	check(host.player_by_peer(client_id) != null, "host simulates the client's warrior")
	await wait_until(func() -> bool: return client.local_warrior != null)
	check(client.local_warrior != null and client.local_warrior.peer_id == client_id, "client plays its own warrior")
	check(client.local_warrior != null and not client.local_warrior.simulated, "client does not simulate it")
	check(client.players.size() == 2, "client sees both warriors, got %d" % client.players.size())
	check(client.get_node("IsoCamera").target == client.local_warrior, "client camera follows its own warrior")
	check(host.local_warrior == host.get_node("Warrior"), "host keeps the scene's warrior")


func test_client_intent_moves_its_warrior_through_the_host() -> void:
	var matches := await start_net_match()
	var host: Match = matches[0]
	var client: Match = matches[1]
	await wait_until(func() -> bool: return client.local_warrior != null)
	var on_host := host.player_by_peer(client.multiplayer.get_unique_id())
	var start := on_host.global_position
	Input.action_press(&"move_right")
	await seconds(1.0)
	Input.action_release(&"move_right")
	check(on_host.global_position.distance_to(start) > 3.0, "host moved the client's warrior from its intent")
	await seconds(0.5)
	check(client.local_warrior.global_position.distance_to(on_host.global_position) < 0.5,
		"client shows where the host put it (off by %.2f m)" % client.local_warrior.global_position.distance_to(on_host.global_position))


func test_client_follows_the_hosts_fortress_and_storage() -> void:
	var matches := await start_net_match()
	var host: Match = matches[0]
	var client: Match = matches[1]
	var host_fortress: Fortress = host.get_node("Fortress")
	var client_fortress: Fortress = client.get_node("Fortress")
	host_fortress.follower.base_speed = 10.0
	host_fortress.storage.add_all({&"wood": 7})
	host_fortress.health.apply_damage(40.0)
	await seconds(1.5)
	check(host_fortress.follower.distance > 10.0, "host fortress moves")
	check_near(client_fortress.follower.distance, host_fortress.follower.distance, 2.0, "client fortress keeps up")
	check(client_fortress.global_position.distance_to(host_fortress.global_position) < 2.0, "client fortress drawn in place")
	check(client_fortress.storage.amounts == host_fortress.storage.amounts, "client sees the shared storage")
	check(client_fortress.health.current == host_fortress.health.current, "client sees fortress damage")


func test_client_cannot_change_the_world_by_itself() -> void:
	var matches := await start_net_match()
	var host: Match = matches[0]
	var client: Match = matches[1]
	await wait_until(func() -> bool: return client.local_warrior != null)
	var client_fortress: Fortress = client.get_node("Fortress")
	var hp := client_fortress.health.current
	client_fortress.health.apply_damage(50.0)
	check(client_fortress.health.current == hp, "client-side damage is ignored")
	var placed := client.request_place(StructureTypes.ALL[0], client.local_warrior.global_position + Vector3(3, 0, 0), client.local_warrior)
	check(not placed, "client cannot place structures on its own")
	check(host.get_node("Structures").get_child_count() == client.get_node("Structures").get_child_count(), "nothing placed")


func test_client_events_reach_the_host() -> void:
	var matches := await start_net_match()
	var host: Match = matches[0]
	var client: Match = matches[1]
	await wait_until(func() -> bool: return client.local_warrior != null)
	var host_fortress: Fortress = host.get_node("Fortress")
	client.local_warrior.input._emit_local(&"overdrive")
	check(not client.get_node("Fortress").overdrive, "client does not toggle overdrive locally")
	check(await wait_until(func() -> bool: return host_fortress.overdrive), "host applies the client's overdrive")
	check(await wait_until(func() -> bool: return client.get_node("Fortress").overdrive), "client sees it back")


func test_client_leaving_removes_its_warrior() -> void:
	var matches := await start_net_match()
	var host: Match = matches[0]
	var client: Match = matches[1]
	var client_id := client.multiplayer.get_unique_id()
	Net.leave(client.multiplayer)
	check(await wait_until(func() -> bool: return host.player_by_peer(client_id) == null, 300), "host drops the warrior")
	check(host.players.size() == 1, "only the host remains")


func test_two_clients_play_together() -> void:
	var matches := await start_net_match(2)
	var host: Match = matches[0]
	check(host.players.size() == 3, "three warriors on the host")
	for client: Match in matches.slice(1):
		check(await wait_until(func() -> bool: return client.players.size() == 3), "each client sees all three")


func test_lobby_counts_players() -> void:
	var matches := await start_net_match(1, 1, 24790, true)
	var host: Match = matches[0]
	var client: Match = matches[1]
	host.host_room()
	client.join_room("127.0.0.1")
	var status: Label = host.get_node("UI/StartMenu")._lobby_status
	check(await wait_until(func() -> bool: return status.text.contains("2/4"), 300), "host lobby shows 2/4, got: " + status.text)
	var client_status: Label = client.get_node("UI/StartMenu")._lobby_status
	check(client_status.text == tr("Đã vào phòng — chờ chủ phòng bắt đầu"), "client waits for the host")


func test_client_input_is_sanitised() -> void:
	var clean := NetSync._clean_state({"move": Vector3(50, 9, 0), "aim": Vector3.ZERO, "attack": "yes", "interact": true, "point": 3})
	check_near(clean.move.length(), 1.0, 0.001, "move clamped to a full stick")
	check(clean.move.y == 0.0, "move stays on the ground")
	check(not clean.has("aim"), "zero aim dropped")
	check(clean.attack == false and clean.interact == true, "only real booleans count")
	check(not clean.has("point"), "wrong types dropped")
