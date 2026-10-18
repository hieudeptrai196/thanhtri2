extends GameTest


func test_stops_departs_and_reaches_end() -> void:
	var m := await start_match()
	var fortress: Fortress = m.get_node("Fortress")
	var follower := fortress.follower
	follower.base_speed = 60.0
	var stops := []
	var ended := [false]
	follower.reached_stop.connect(func(index: int) -> void: stops.append(index))
	follower.reached_end.connect(func() -> void: ended[0] = true)

	var last := fortress.global_position
	var facing_errors := 0
	for i in 1200:
		await frames(1)
		var move := fortress.global_position - last
		if move.length() > 0.01 and (-fortress.global_basis.z).dot(move.normalized()) < 0.9:
			facing_errors += 1
		last = fortress.global_position
		if follower.is_stopped and stops.size() == 1:
			check_near(fortress.global_position.distance_to(Vector3(40, 0, -140)), 0.0, 1.0, "stop position")
			await frames(30)
			check(follower.is_stopped, "stays stopped until departure")
			follower.depart()
		if ended[0]:
			break

	check(stops == [0], "stops once at the stop marker, got %s" % [stops])
	check(ended[0], "reaches the end of the route")
	check_near(fortress.global_position.distance_to(Vector3(0, 0, -220)), 0.0, 0.5, "end position")
	check(facing_errors == 0, "faces its travel direction (%d bad frames)" % facing_errors)


func test_speed_scales_with_health() -> void:
	var m := await start_match()
	var fortress: Fortress = m.get_node("Fortress")
	fortress.health.apply_damage(250.0)
	check_near(fortress.follower.speed_multiplier, 0.7, 0.001, "multiplier at half health")
	var start := fortress.follower.progress
	await seconds(1.0)
	check_near(fortress.follower.progress - start, 2.1, 0.1, "measured speed at half health (m/s)")
	fortress.health.apply_damage(9999.0)
	check_near(fortress.follower.speed_multiplier, 0.4, 0.001, "multiplier at zero health (floor)")
