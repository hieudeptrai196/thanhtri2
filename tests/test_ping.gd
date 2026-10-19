extends GameTest
## M2.3c: one context-sensitive ping key marks a point for the team.


func _pings(m: Match) -> Array:
	return m.get_children().filter(func(n: Node) -> bool: return n is PingMarker and not n.is_queued_for_deletion())


func _setup(m: Match) -> Warrior:
	var fortress: Fortress = m.get_node("Fortress")
	fortress.follower.base_speed = 0.0
	clear_random_bombs(m)
	var warrior: Warrior = m.get_node("Warrior")
	warrior.global_position = fortress.global_position + Vector3(12, 0.1, 0)
	await frames(2)
	return warrior


# Pings one point and returns the newest marker (waits out the anti-spam cooldown first).
func _ping(m: Match, warrior: Warrior, point: Vector3) -> PingMarker:
	await seconds(Match.PING_COOLDOWN + 0.05)
	warrior.input.emit_ping(point)
	await frames(1)
	var markers := _pings(m)
	return markers.back() if not markers.is_empty() else null


func test_ping_meaning_follows_what_is_there() -> void:
	var m: Match = await start_match()
	var fortress: Fortress = m.get_node("Fortress")
	var warrior := await _setup(m)
	var origin := fortress.global_position
	var ground := await _ping(m, warrior, origin + Vector3(20, 0, 20))
	check(ground != null and ground.kind == &"ground", "plain ground: come here")
	check(ground != null and ground.text() == "Đến đây", "the mark reads its meaning")
	var on_fortress := await _ping(m, warrior, origin + Vector3(1, 0, 1))
	check(on_fortress.kind == &"fortress", "on the fortress: defend it")
	var tree_node := spawn_resource(m, TREE_SCENE, origin + Vector3(15, 0, -15))
	var on_tree := await _ping(m, warrior, tree_node.global_position + Vector3(0.5, 0, 0))
	check(on_tree.kind == &"resource" and on_tree.text() == "Lấy Gỗ ở đây", "on a tree: get wood here (%s)" % on_tree.text())
	var enemy: Enemy = m.get_node("Spawner").spawn_one()
	enemy.move_speed = 0.0
	enemy.global_position = origin + Vector3(-18, 0, 18)
	var on_enemy := await _ping(m, warrior, enemy.global_position + Vector3(1, 0, 0))
	check(on_enemy.kind == &"enemy", "on an enemy: enemies here")
	var network: StructureNetwork = m.get_node("Structures")
	var blueprint := network.place_blueprint(StructureTypes.ALL[0], origin + Vector3(-25, 0, -25))
	var on_blueprint := await _ping(m, warrior, blueprint.global_position)
	check(on_blueprint.kind == &"blueprint", "on a blueprint: help build")
	var built := network.place(StructureTypes.ALL[0], origin + Vector3(25, 0, -30))
	var on_built := await _ping(m, warrior, built.global_position)
	check(on_built.kind == &"structure" and on_built.text() == "Thu %s này" % tr(StructureTypes.ALL[0].display_name),
		"on a finished structure: take it along (%s)" % on_built.text())


func test_one_mark_per_player_and_no_spam() -> void:
	var m: Match = await start_match()
	var warrior := await _setup(m)
	var first := await _ping(m, warrior, warrior.global_position + Vector3(5, 0, 0))
	warrior.input.emit_ping(warrior.global_position + Vector3(-5, 0, 0))  # inside the cooldown
	await frames(1)
	check(_pings(m).size() == 1 and _pings(m)[0] == first, "a ping right after another is ignored")
	var second := await _ping(m, warrior, warrior.global_position + Vector3(0, 0, 5))
	check(_pings(m).size() == 1 and second != first, "a new ping replaces the player's previous one")


func test_mark_fades_away() -> void:
	var m: Match = await start_match()
	var warrior := await _setup(m)
	var marker := await _ping(m, warrior, warrior.global_position + Vector3(5, 0, 0))
	check(marker != null, "marked")
	await seconds(PingMarker.LIFETIME + 0.2)
	check(not is_instance_valid(marker), "gone after a few seconds")


func test_far_pings_are_pulled_in() -> void:
	var m: Match = await start_match()
	var warrior := await _setup(m)
	var marker := await _ping(m, warrior, warrior.global_position + Vector3(500, 0, 0))
	var distance := Vector2(marker.global_position.x - warrior.global_position.x, marker.global_position.z - warrior.global_position.z).length()
	check_near(distance, Match.PING_MAX_DISTANCE, 0.1, "kept within reach of the player")


func test_edge_arrow_only_for_off_screen_pings() -> void:
	var rect := Rect2(0, 0, 1280, 720)
	check(PingIndicators.edge_point(Vector2(640, 360), false, rect, 36.0) == null, "on screen: no arrow")
	var right: Vector2 = PingIndicators.edge_point(Vector2(3000, 360), false, rect, 36.0)
	check_near(right.x, 1280 - 36.0, 0.5, "off to the right: arrow at the right edge")
	check_near(right.y, 360.0, 0.5, "level with it")
	var behind: Vector2 = PingIndicators.edge_point(Vector2(640, 100), true, rect, 36.0)
	check(behind.y > 360.0, "behind the camera: flipped")


func test_client_ping_shows_on_every_machine() -> void:
	var matches := await start_net_match(1, 1, 24840)
	var host: Match = matches[0]
	var client: Match = matches[1]
	host.get_node("Fortress").follower.base_speed = 0.0
	var me := client.local_warrior
	await seconds(Match.PING_COOLDOWN)
	me.input.emit_ping(me.global_position + Vector3(6, 0, 0))
	var on_host := await wait_until(func() -> bool: return not _pings(host).is_empty(), 60)
	var on_client := await wait_until(func() -> bool: return not _pings(client).is_empty(), 60)
	check(on_host and _pings(host)[0].peer_id == me.peer_id, "the host shows the client's ping")
	check(on_client and _pings(client)[0].peer_id == me.peer_id, "the client gets it back from the host")
	if on_client:
		check(_pings(client)[0].color == me.display_color(), "in the pinging player's colour")
