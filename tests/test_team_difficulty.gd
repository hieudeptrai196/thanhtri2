extends GameTest
## M2.4: more players, more monsters; joining and leaving mid-run adjusts it at once.

const DIFFICULTY := preload("res://match/difficulty_default.tres")


func test_solo_numbers_unchanged() -> void:
	var d := DIFFICULTY
	for distance in [0.0, 1500.0, 6000.0]:
		check(d.spawn_interval(distance, 1) == d.spawn_interval(distance), "interval at %d m" % distance)
		check(d.max_alive(distance, 1) == d.max_alive(distance), "cap at %d m" % distance)
		check(d.health_multiplier(distance, 1) == d.health_multiplier(distance), "health at %d m" % distance)
		check(d.pack_size(distance, 1) == d.pack_size(distance), "pack at %d m" % distance)


func test_five_players_face_more_monsters() -> void:
	var d := DIFFICULTY
	var extra := 4
	check_near(d.spawn_interval(0.0, 5), d.spawn_interval(0.0) / (1.0 + d.spawn_rate_per_player * extra), 0.001, "waves come more often")
	check(d.pack_size(0.0, 5) == d.pack_size(0.0) + floori(d.pack_per_player * extra), "bigger waves")
	check(d.max_alive(0.0, 5) == roundi(d.max_alive(0.0) * (1.0 + d.max_alive_per_player * extra)), "higher alive cap")
	check(d.max_alive(50000.0, 5) == d.team_max_alive_cap, "the team cap holds far down the road")
	check_near(d.health_multiplier(0.0, 5), 1.0 + d.health_per_player * extra, 0.001, "tougher monsters")
	check(d.spawn_interval(0.0, 3) > d.spawn_interval(0.0, 5) and d.spawn_interval(0.0, 3) < d.spawn_interval(0.0, 1),
		"grows steadily with each player")


func test_team_size_follows_joins_and_leaves() -> void:
	var m: Match = await start_match()
	var spawner: Spawner = m.get_node("Spawner")
	check(spawner.team_size == 1, "solo")
	var mate: Warrior = m.spawn_player(2)
	mate.input.remote = true
	m.spawn_player(3).input.remote = true
	check(spawner.team_size == 3, "two joined")
	m.remove_player(2)
	await frames(1)
	check(spawner.team_size == 2, "one left")
	var duo: float = spawner.spawn_one().get_node("Health").max_health
	m.remove_player(3)
	await frames(1)
	var solo: float = spawner.spawn_one().get_node("Health").max_health
	check_near(duo / solo, 1.0 + DIFFICULTY.health_per_player, 0.001, "enemies spawned with a teammate are tougher")


func test_leaving_drops_what_was_carried() -> void:
	var m: Match = await start_match()
	var fortress: Fortress = m.get_node("Fortress")
	fortress.follower.base_speed = 0.0
	var mate: Warrior = m.spawn_player(2)
	mate.input.remote = true
	mate.global_position = fortress.global_position + Vector3(25, 0.1, 25)
	await frames(2)
	mate.inventory.add(&"wood", 7)
	mate.carry(StructureTypes.ALL[0], 40.0)
	var spot := mate.global_position
	var structures_before: int = (m.get_node("Structures") as StructureNetwork).structures().size()
	m.remove_player(2)
	await frames(2)
	var piles := m.get_node("Pickups").get_children()
	check(piles.size() == 1 and piles[0].global_position.distance_to(spot) < 1.5, "a pile where the player stood")
	check(piles.size() == 1 and piles[0].contents.get(&"wood", 0) == 7, "with their wood")
	check((m.get_node("Structures") as StructureNetwork).structures().size() == structures_before + 1, "and their folded structure")


func test_client_leaving_mid_run_eases_the_host() -> void:
	var matches := await start_net_match(1, 1, 24860)
	var host: Match = matches[0]
	var client: Match = matches[1]
	var spawner: Spawner = host.get_node("Spawner")
	check(spawner.team_size == 2, "two players online")
	var client_id := client.multiplayer.get_unique_id()
	Net.leave(client.multiplayer)
	check(await wait_until(func() -> bool: return host.player_by_peer(client_id) == null, 300), "client gone")
	check(spawner.team_size == 1, "back to solo difficulty")
