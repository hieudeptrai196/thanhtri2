extends GameTest

const FOREST := preload("res://world/routes/old_forest.tres")
const PLAINS := preload("res://world/routes/plains.tres")
const TEMPLE := preload("res://world/routes/ruined_temple.tres")


func _match_at_stop(rng_seed: int = 1) -> Node:
	var m := await start_match(rng_seed)
	var follower: RouteFollower = m.get_node("Fortress/RouteFollower")
	m.get_node("Fortress").storage.add(&"coal", 100)
	follower.base_speed = 300.0
	for i in 300:
		await frames(1)
		if follower.is_stopped:
			break
	check(follower.is_stopped, "fortress reaches the stop")
	return m


func _resources_between(m: Node, from: float, to: float, id: StringName) -> int:
	var count := 0
	for entry in m.get_node("RouteContent")._spawned:
		if is_instance_valid(entry[0]) and entry[0] is ResourceNode and entry[0].resource_type.id == id and entry[1] >= from and entry[1] < to:
			count += 1
	return count


func test_stop_offers_two_routes_deterministically() -> void:
	var m := await _match_at_stop(21)
	var first: Array = m.route_offers.map(func(r: RouteType) -> StringName: return r.id)
	check(first.size() == 2 and first[0] != first[1], "two different routes offered: %s" % [first])
	m = await _match_at_stop(21)
	check(m.route_offers.map(func(r: RouteType) -> StringName: return r.id) == first, "same seed, same offer")


func test_content_past_the_stop_waits_for_the_choice() -> void:
	var m := await _match_at_stop()
	var route: EndlessRoute = m.get_node("Route")
	var stop := route.stop_distance(0)
	var beyond := _resources_between(m, stop + route.segment_length, INF, &"wood") + _resources_between(m, stop + route.segment_length, INF, &"coal")
	check(beyond == 0, "nothing placed past the stop before choosing, found %d" % beyond)
	m.request_route(0)
	m.get_node("Fortress/RouteFollower").depart()
	await frames(2)
	var placed := _resources_between(m, stop, route.stop_distance(1), &"wood") + _resources_between(m, stop, route.stop_distance(1), &"coal")
	check(placed > 0, "the next stretch is filled once a route is picked (%d)" % placed)


func test_route_changes_the_roadside_and_enemies() -> void:
	var counts := {}
	for type in [FOREST, PLAINS]:
		var m := await _match_at_stop(5)
		m.route_offers = Array([type, TEMPLE], TYPE_OBJECT, &"Resource", RouteType)
		m.request_route(0)
		m.get_node("Fortress/RouteFollower").depart()
		await frames(2)
		var route: EndlessRoute = m.get_node("Route")
		route.ensure_ahead(route.stop_distance(1))
		counts[type.id] = _resources_between(m, route.stop_distance(0), route.stop_distance(1), &"wood")
		var spawner: Spawner = m.get_node("Spawner")
		check(spawner.route_rate_multiplier == type.enemy_rate_multiplier, "%s sets the enemy rate" % type.id)
		check(m.current_route == type, "%s is the current route" % type.id)
	check(counts[&"old_forest"] > counts[&"plains"] * 2, "the old forest has far more trees: %s" % counts)


func test_departing_without_choosing_takes_the_first_offer() -> void:
	var m := await _match_at_stop()
	var first: RouteType = m.route_offers[0]
	m.get_node("Fortress/RouteFollower").depart()
	await frames(1)
	check(m.current_route == first, "first offer applied by default")


func test_temple_enemies_are_tougher_and_drop_more() -> void:
	var m := await _match_at_stop()
	m.route_offers = Array([TEMPLE, PLAINS], TYPE_OBJECT, &"Resource", RouteType)
	m.request_route(0)
	m.get_node("Fortress/RouteFollower").depart()
	await frames(2)
	m.get_node("Fortress/RouteFollower").base_speed = 0.0  # or the next stop clears the enemy first
	m.get_node("Spawner").active = false
	var warrior: Warrior = m.get_node("Warrior")
	warrior.global_position = m.get_node("Fortress").global_position + Vector3(30, 0.1, 0)
	var enemy: Enemy = m.get_node("Spawner").spawn_one()
	check(enemy.get_node("Health").max_health > 30.0 * 1.29, "temple enemies have more health")
	enemy.global_position = warrior.global_position + Vector3(2, 0, 3)
	check(await attack_until_freed(warrior, enemy, 600), "the warrior kills it")
	await frames(2)
	var bronze := warrior.inventory.get_amount(&"bronze")  # the warrior may already have picked it up
	for pile: Pickup in m.get_node("Pickups").get_children():
		bronze += pile.contents.get(&"bronze", 0)
	check(bronze == 2, "and drop twice the bronze, got %d" % bronze)


func test_panel_route_cards_pick_a_route() -> void:
	var m := await _match_at_stop()
	var panel: UpgradePanel = m.get_node("UI/UpgradePanel")
	check(panel._route_cards.size() == 2, "two route cards")
	panel._route_cards[1].pressed.emit()
	check(m.route_choice == 1, "pressing a card picks that route")
	var ground: ShaderMaterial = m.get_node("Ground/Mesh").mesh.material
	m.get_node("Fortress/RouteFollower").depart()
	await frames(1)
	check(ground.get_shader_parameter(&"color_a") == m.route_offers[1].ground_color_a, "the ground takes the route's colour")
