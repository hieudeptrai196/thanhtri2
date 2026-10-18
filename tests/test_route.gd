extends GameTest


func _make_route(route_seed: int) -> EndlessRoute:
	var route := EndlessRoute.new()
	tree.root.add_child(route)
	var rng := RandomNumberGenerator.new()
	rng.seed = route_seed
	route.setup(rng)
	return route


func test_same_seed_same_road_different_seed_different_road() -> void:
	var a := _make_route(11)
	var b := _make_route(11)
	var c := _make_route(12)
	for route in [a, b, c]:
		route.ensure_ahead(600.0)
	check(a.position_at(600.0).distance_to(b.position_at(600.0)) < 0.001, "same seed gives the same road")
	check(a.position_at(600.0).distance_to(c.position_at(600.0)) > 1.0, "another seed gives another road")
	for route in [a, b, c]:
		route.free()


func test_road_never_turns_back_and_stays_bounded() -> void:
	var route := _make_route(3)
	var max_points := 0
	var backwards := 0
	var distance := 0.0
	while distance < 5000.0:
		route.ensure_ahead(distance)
		max_points = maxi(max_points, route.curve.point_count)
		var forward := -route.sample(distance).basis.z.normalized()
		if forward.dot(Vector3.FORWARD) < cos(deg_to_rad(route.max_heading_degrees + 10.0)):
			backwards += 1
		distance += 10.0
	check(backwards == 0, "road keeps heading forward (%d bad samples)" % backwards)
	var expected_points := ceili((route.look_ahead + route.keep_behind) / route.segment_length) + 3
	check(max_points <= expected_points, "old road is dropped: max %d points (limit %d)" % [max_points, expected_points])
	check(route.base_distance > 4500.0, "curve start moved forward to %.0f m" % route.base_distance)
	var step := route.position_at(4999.0).distance_to(route.position_at(5000.0))
	check_near(step, 1.0, 0.1, "1 m of route distance is ~1 m of road after trimming")
	route.free()


func test_match_road_ignores_gameplay_randomness() -> void:
	var m := await start_match(7)
	var spawner: Spawner = m.get_node("Spawner")
	for i in 40:
		spawner.spawn_one()  # burns gameplay RNG
	var route: EndlessRoute = m.get_node("Route")
	route.ensure_ahead(700.0)
	var with_spawns := route.position_at(800.0)

	m = await start_match(7)
	route = m.get_node("Route")
	route.ensure_ahead(700.0)
	check(route.position_at(800.0).distance_to(with_spawns) < 0.001, "road depends only on the seed")


func test_content_layout() -> void:
	var m := await start_match(5)
	var route: EndlessRoute = m.get_node("Route")
	var content: RouteContent = m.get_node("RouteContent")
	route.keep_behind = 5000.0  # keep the whole road so positions can be checked against it
	route.ensure_ahead(1200.0)
	var trees := 0
	var rocks := 0
	var markers := 0
	var strips := 0
	for entry in content._spawned:
		var node: Node3D = entry[0]
		var at: float = entry[1]
		var lateral := Vector2(node.global_position.x, node.global_position.z).distance_to(
			Vector2(route.position_at(at).x, route.position_at(at).z))
		if node is ResourceNode:
			check(at >= content.clear_start, "no resources in the clear start (%.0f m)" % at)
			check(lateral >= content.road_half_width - 0.01, "resource %.1f m off the road centre" % lateral)
			if node.resource_type.id == &"wood":
				trees += 1
			else:
				rocks += 1
		elif node is MeshInstance3D:
			strips += 1
		elif node is HiddenBomb:
			check(lateral < 0.01, "bombs sit on the road")
			var nearest := route.stop_distance(maxi(roundi((at - route.first_stop) / route.stop_interval), 0))
			check(absf(at - nearest) >= content.bomb_stop_margin, "bomb %.0f m is away from stops" % at)
		else:
			markers += 1
	check(trees > 20 and rocks > 5, "trees and rocks along 1.2 km: %d trees, %d rocks" % [trees, rocks])
	check(markers == 3, "stop markers at 350/700/1050 m, got %d" % markers)
	var expected_strips := ceili(route.generated_to() / route.segment_length)
	check(absi(strips - expected_strips) <= 1, "one road strip per segment: %d strips, ~%d segments" % [strips, expected_strips])

	content.despawn_before(900.0)
	await frames(1)
	var stale := content._spawned.filter(func(e: Array) -> bool: return is_instance_valid(e[0]) and e[1] < 900.0 - content.despawn_behind)
	check(stale.is_empty(), "content far behind is freed (%d left)" % stale.size())


func test_warrior_is_kept_near_the_fortress() -> void:
	var m := await start_match()
	var fortress: Fortress = m.get_node("Fortress")
	fortress.follower.base_speed = 0.0
	var warrior: Warrior = m.get_node("Warrior")
	warrior.global_position = fortress.global_position + Vector3(150, 0.1, 0)
	await frames(2)
	var offset := warrior.global_position - fortress.global_position
	offset.y = 0.0
	check(offset.length() <= m.leash_radius + 0.5, "warrior pulled back to %.1f m" % offset.length())


func test_long_run_keeps_node_count_bounded() -> void:
	var m := await start_match(9)
	var follower: RouteFollower = m.get_node("Fortress/RouteFollower")
	m.get_node("Fortress").health.set_max_health(1e9)  # ~13 bombs on 4 km would end the run
	follower.base_speed = 300.0
	var counts: Array[int] = []
	for i in 3000:
		if follower.distance >= 4000.0 or m.result != 0:
			break
		await frames(1)
		if follower.is_stopped:
			follower.depart()
		if counts.size() < int(follower.distance / 1000.0) + 1:
			counts.append(int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
	check(counts.size() >= 4, "sampled every km: %s" % [counts])
	check(counts[-1] - counts[1] < 150, "node count stays flat over 4 km: %s" % [counts])
