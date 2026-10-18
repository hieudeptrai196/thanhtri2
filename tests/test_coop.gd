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


func test_client_sees_the_hosts_enemies() -> void:
	var matches := await start_net_match()
	var host: Match = matches[0]
	var client: Match = matches[1]
	var host_spawner: Spawner = host.get_node("Spawner")
	var client_spawner: Spawner = client.get_node("Spawner")
	for i in 5:
		host_spawner.spawn_one()
	check(await wait_until(func() -> bool: return client_spawner.alive_count() == 5), "client shows the 5 enemies, got %d" % client_spawner.alive_count())
	await seconds(1.0)
	var host_enemy: Enemy = host_spawner.get_child(0)
	var client_enemy: Enemy = client_spawner._by_net_id.get(host_enemy.net_id)
	check(client_enemy != null, "same enemy known by id")
	if client_enemy:
		check(client_enemy.global_position.distance_to(host_enemy.global_position) < 1.0,
			"client enemy follows the host's (off by %.2f m)" % client_enemy.global_position.distance_to(host_enemy.global_position))
		check(not client_enemy.is_physics_processing(), "client does not simulate enemies")
		host_enemy.get_node("Health").apply_damage(1.0)
		var client_health: HealthComponent = client_enemy.get_node("Health")
		check(await wait_until(func() -> bool: return client_health.current < client_health.max_health), "client sees the hit")
		host_enemy.get_node("Health").apply_damage(9999.0)
		var client_enemy_id := client_enemy.get_instance_id()
		check(await wait_until(func() -> bool: return not is_instance_id_valid(client_enemy_id)), "client enemy disappears when it dies")
	host_spawner.clear()
	check(await wait_until(func() -> bool: return client_spawner.alive_count() == 0), "cleared on both machines")


func test_client_enemies_do_no_damage_by_themselves() -> void:
	var matches := await start_net_match()
	var host: Match = matches[0]
	var client: Match = matches[1]
	var host_fortress: Fortress = host.get_node("Fortress")
	var host_spawner: Spawner = host.get_node("Spawner")
	host_fortress.follower.base_speed = 0.0
	for warrior in host.players:
		warrior.global_position = host_fortress.global_position + Vector3(0, 0.1, 30)  # out of the enemy's aggro
	var enemy := host_spawner.spawn_one()
	enemy.global_position = host_fortress.global_position + Vector3(3, 0, 0)
	enemy.get_node("Health").set_max_health(1e6)  # outlive the fortress's own defences
	var damage := enemy.damage
	host_fortress.health.set_max_health(1e6)
	host_fortress.health.reset()
	await seconds(2.0)
	var host_lost := host_fortress.health.max_health - host_fortress.health.current
	check(host_lost > 0.0, "the enemy hits the fortress on the host")
	var client_fortress: Fortress = client.get_node("Fortress")
	check_near(client_fortress.health.max_health - client_fortress.health.current, host_lost, damage * 2.0,
		"client fortress loses only what the host says")


func test_client_sees_structures_being_built_and_recovered() -> void:
	var matches := await start_net_match()
	var host: Match = matches[0]
	var client: Match = matches[1]
	var host_net: StructureNetwork = host.get_node("Structures")
	var client_net: StructureNetwork = client.get_node("Structures")
	var fortress: Fortress = host.get_node("Fortress")
	fortress.follower.base_speed = 0.0
	var spot := fortress.global_transform * Vector3(14.0, 0.0, 0.0)
	var blueprint := host_net.place_blueprint(StructureTypes.ALL[0], spot)
	check(await wait_until(func() -> bool: return client_net.structures().size() == 1), "client sees the blueprint")
	var shown: Structure = client_net.structures()[0] if client_net.structures().size() == 1 else null
	if shown == null:
		return
	check(not shown.built and shown.global_position.distance_to(spot) < 0.1, "as an unbuilt blueprint in place")
	fortress.storage.add_all({&"wood": 50})
	var purse := Inventory.new()
	while not blueprint.built:
		blueprint.add_hammer(purse)
		await frames(1)
	check(await wait_until(func() -> bool: return shown.built), "client sees it finished")
	host_net.recover(blueprint)
	check(await wait_until(func() -> bool: return client_net.structures().is_empty()), "client removes it when recovered")
	purse.free()


func test_client_builds_through_its_intent() -> void:
	var matches := await start_net_match()
	var host: Match = matches[0]
	var client: Match = matches[1]
	await wait_until(func() -> bool: return client.local_warrior != null)
	var fortress: Fortress = host.get_node("Fortress")
	fortress.follower.base_speed = 0.0
	fortress.storage.add_all({&"wood": 50})
	var on_host := host.player_by_peer(client.multiplayer.get_unique_id())
	on_host.global_position = fortress.global_transform * Vector3(14.0, 0.1, 0.0)
	host.local_warrior.global_position = fortress.global_transform * Vector3(-30.0, 0.1, 0.0)
	# Aim away from the road with the stick, as seen by the client's camera (Input is shared).
	var camera: Camera3D = client.get_node("IsoCamera")
	var away := fortress.global_basis.x.normalized()
	var right := Vector3(camera.global_basis.x.x, 0.0, camera.global_basis.x.z).normalized()
	var forward := Vector3(-camera.global_basis.z.x, 0.0, -camera.global_basis.z.z).normalized()
	var stick := Vector2(away.dot(right), -away.dot(forward))
	Input.action_press(&"aim_right" if stick.x > 0.0 else &"aim_left", absf(stick.x))
	Input.action_press(&"aim_down" if stick.y > 0.0 else &"aim_up", absf(stick.y))
	await seconds(0.3)
	var input := client.local_warrior.input
	input.local_events.append([&"select", 0])
	await frames(5)
	check(on_host.builder.selected == StructureTypes.ALL[0], "host sees the client pick a structure")
	check(client.local_warrior.builder.selected == null, "the client's own pick waits for its local key (none pressed)")
	input.local_events.append([&"place"])
	var host_net: StructureNetwork = host.get_node("Structures")
	check(await wait_until(func() -> bool: return host_net.structures().size() == 1), "host places the client's blueprint")
	input.local_events.append([&"cancel"])
	await frames(5)
	var blueprint: Structure = host_net.structures()[0] if host_net.structures().size() == 1 else null
	if blueprint == null:
		return
	on_host.global_position = blueprint.global_position + Vector3(1.0, 0.1, 0.0)
	await seconds(0.3)
	Input.action_press(&"interact")
	var built := await wait_until(func() -> bool: return blueprint.built, 600)
	Input.action_release(&"interact")
	check(built, "client's held interact hammers the blueprint on the host")
	var client_net: StructureNetwork = client.get_node("Structures")
	check(await wait_until(func() -> bool: return client_net.structures().size() == 1 and client_net.structures()[0].built),
		"client sees it built")


func test_client_sees_trees_depleting_and_bombs_exploding() -> void:
	var matches := await start_net_match()
	var host: Match = matches[0]
	var client: Match = matches[1]
	var host_content: RouteContent = host.get_node("RouteContent")
	var client_content: RouteContent = client.get_node("RouteContent")
	var trees := host_content.resource_nodes(&"wood")
	check(not trees.is_empty(), "the road has trees")
	if trees.is_empty():
		return
	var tree_node := trees[0]
	var id: int = host_content._by_content_id.find_key(tree_node)
	var mirror: ResourceNode = client_content._by_content_id.get(id)
	check(mirror != null and mirror.global_position.distance_to(tree_node.global_position) < 0.01,
		"same tree under the same id on the client")
	if mirror == null:
		return
	var mirror_id := mirror.get_instance_id()
	var gatherer := host.local_warrior
	gatherer.inventory.capacity = 1000
	tree_node._on_hit_taken(1.0, gatherer)
	check(await wait_until(func() -> bool: return mirror.amount == tree_node.amount), "client tree loses the unit")
	while tree_node.amount > 0:  # freed only at the end of the frame
		tree_node._on_hit_taken(1.0, gatherer)
	check(await wait_until(func() -> bool: return not is_instance_id_valid(mirror_id)), "client tree is gone when chopped down")

	var bomb := host_content.place_bomb(80.0)
	var client_bomb := client_content.place_bomb(80.0)
	var bomb_id: int = host_content._by_content_id.find_key(bomb)
	check(client_content._by_content_id.get(bomb_id) == client_bomb, "bombs line up by id")
	bomb._on_area_entered(host.get_node("Fortress/Hurtbox"))
	check(await wait_until(func() -> bool: return client_bomb._spent), "client bomb explodes too")
	check(client.get_node("UI/HUD/%Toast").text.contains(tr("bom")), "client is warned, toast: " + client.get_node("UI/HUD/%Toast").text)


func test_client_sees_pickups_and_toasts() -> void:
	var matches := await start_net_match()
	var host: Match = matches[0]
	var client: Match = matches[1]
	var at: Vector3 = host.get_node("Fortress").global_position + Vector3(20, 0, 20)
	host._spawn_pickup({&"bronze": 2}, at)
	var client_piles: Node3D = client.get_node("Pickups")
	check(await wait_until(func() -> bool: return client_piles.get_child_count() == 1), "client sees the pile")
	if client_piles.get_child_count() == 1:
		check(client_piles.get_child(0).global_position.distance_to(Vector3(at.x, 0, at.z)) < 0.01, "in place")
	for pile in host.get_node("Pickups").get_children():
		pile.queue_free()
	check(await wait_until(func() -> bool: return client_piles.get_child_count() == 0), "and sees it go")
	host.request_overdrive()
	var toast: Label = client.get_node("UI/HUD/%Toast")
	check(await wait_until(func() -> bool: return toast.text == tr("Tăng tốc! Tốn Than gấp nhiều lần")), "client gets the host's toast")


## Drives the host's fortress to its first stop and waits for the client to show the panel.
func _reach_stop(host: Match, client: Match) -> bool:
	var follower: RouteFollower = host.get_node("Fortress/RouteFollower")
	follower.base_speed = 300.0
	await wait_until(func() -> bool: return follower.is_stopped, 600)
	follower.base_speed = 0.0
	return await wait_until(func() -> bool: return client.get_node("UI/UpgradePanel").visible)


func test_stop_panel_opens_on_every_machine() -> void:
	var matches := await start_net_match()
	var host: Match = matches[0]
	var client: Match = matches[1]
	check(await _reach_stop(host, client), "client shows the stop panel")
	check(client.weapon_offers == host.weapon_offers, "same weapon cards offered")
	check(client.route_offers == host.route_offers, "same routes offered")
	client.get_node("UI/UpgradePanel").route_requested.emit(1)
	check(await wait_until(func() -> bool: return host.route_choice == 1), "client picks the route on the host")
	check(await wait_until(func() -> bool: return client.route_choice == 1), "and sees the pick")


func test_fortress_leaves_only_when_everyone_is_ready() -> void:
	var matches := await start_net_match()
	var host: Match = matches[0]
	var client: Match = matches[1]
	await _reach_stop(host, client)
	var follower: RouteFollower = host.get_node("Fortress/RouteFollower")
	host.get_node("UI/UpgradePanel").depart_requested.emit()
	await seconds(0.5)
	check(follower.is_stopped, "the host alone is not enough")
	var client_panel: UpgradePanel = client.get_node("UI/UpgradePanel")
	check(await wait_until(func() -> bool: return client_panel._depart.text.contains("1/2")), "client sees 1/2 ready: " + client_panel._depart.text)
	client_panel.depart_requested.emit()
	check(await wait_until(func() -> bool: return not follower.is_stopped), "everyone ready: the fortress departs")
	check(await wait_until(func() -> bool: return not client_panel.visible), "client panel closes")
	check(client.current_route == host.current_route, "client drives the chosen route")


func test_a_leaving_player_does_not_block_departure() -> void:
	var matches := await start_net_match()
	var host: Match = matches[0]
	var client: Match = matches[1]
	await _reach_stop(host, client)
	var follower: RouteFollower = host.get_node("Fortress/RouteFollower")
	host.get_node("UI/UpgradePanel").depart_requested.emit()
	await seconds(0.3)
	Net.leave(client.multiplayer)
	check(await wait_until(func() -> bool: return not follower.is_stopped, 300), "departs once the waiting player is gone")


func test_each_player_buys_their_own_weapon_card() -> void:
	var matches := await start_net_match()
	var host: Match = matches[0]
	var client: Match = matches[1]
	await _reach_stop(host, client)
	var storage: Inventory = host.get_node("Fortress").storage
	storage.add_all({&"bronze": 100})
	check(host.request_weapon_upgrade(0), "host buys a card")
	var client_warrior := host.player_by_peer(client.multiplayer.get_unique_id())
	var weapon_before := [client_warrior.weapon.damage, client_warrior.weapon.cooldown, client_warrior.weapon.arc_degrees, client_warrior.weapon._reach_shape.radius]
	client.get_node("UI/UpgradePanel").weapon_upgrade_requested.emit(0)
	check(await wait_until(func() -> bool: return host._weapon_choices.has(client_warrior.peer_id)), "the client buys its own card")
	check(await wait_until(func() -> bool: return client.weapon_choice == 0), "client sees its card as bought")
	check([client_warrior.weapon.damage, client_warrior.weapon.cooldown, client_warrior.weapon.arc_degrees, client_warrior.weapon._reach_shape.radius] != weapon_before,
		"the card changes the client's own weapon")
	check(not host.request_weapon_upgrade(1, client_warrior), "still one card per player")
