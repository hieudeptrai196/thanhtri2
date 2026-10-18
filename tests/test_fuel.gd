extends GameTest


func test_marching_burns_coal_slowly() -> void:
	var m := await start_match()
	var fortress: Fortress = m.get_node("Fortress")
	fortress.storage.add(&"coal", 5)
	await seconds(16.2)
	check(fortress.storage.get_amount(&"coal") == 3, "about 0.125 coal per second (2 in 16 s), left %d" % fortress.storage.get_amount(&"coal"))
	check(fortress.speed_mode == Fortress.SpeedMode.MARCH, "still marching")


func test_overdrive_is_faster_and_burns_more() -> void:
	var m := await start_match()
	var fortress: Fortress = m.get_node("Fortress")
	fortress.storage.add(&"coal", 10)
	m.request_overdrive()
	await frames(2)
	check(fortress.speed_mode == Fortress.SpeedMode.OVERDRIVE, "overdrive on")
	check_near(fortress.follower.speed_multiplier, fortress.overdrive_speed, 0.001, "overdrive speed")
	var start := fortress.follower.distance
	await seconds(5.0)
	check_near(fortress.follower.distance - start, 5.0 * fortress.follower.base_speed * fortress.overdrive_speed, 0.3, "distance in 5 s of overdrive")
	check(fortress.storage.get_amount(&"coal") == 7, "about 0.6 coal per second (3 in 5 s), left %d" % fortress.storage.get_amount(&"coal"))
	m.request_overdrive()
	await frames(2)
	check(fortress.speed_mode == Fortress.SpeedMode.MARCH, "toggling again returns to marching")


func test_out_of_coal_crawls_until_refuelled() -> void:
	var m := await start_match()
	var fortress: Fortress = m.get_node("Fortress")
	m.request_overdrive()
	await seconds(2.5)
	check(fortress.speed_mode == Fortress.SpeedMode.OUT_OF_FUEL, "an empty storage runs out of fuel")
	check_near(fortress.follower.speed_multiplier, fortress.out_of_fuel_speed, 0.001, "crawls without coal, even in overdrive")
	fortress.storage.add(&"coal", 3)
	await frames(2)
	check(fortress.speed_mode == Fortress.SpeedMode.OVERDRIVE, "coal brings it back")


func test_no_coal_burned_while_stopped() -> void:
	var m := await start_match()
	var fortress: Fortress = m.get_node("Fortress")
	fortress.storage.add(&"coal", 50)
	fortress.follower.base_speed = 300.0
	for i in 300:
		await frames(1)
		if fortress.follower.is_stopped:
			break
	var at_stop := fortress.storage.get_amount(&"coal")
	await seconds(10.0)
	check(fortress.storage.get_amount(&"coal") == at_stop, "a stopped fortress burns nothing")


func test_t_key_toggles_overdrive() -> void:
	var m := await start_match()
	var fortress: Fortress = m.get_node("Fortress")
	fortress.storage.add(&"coal", 10)
	var key := InputEventKey.new()
	key.physical_keycode = KEY_T
	key.pressed = true
	Input.parse_input_event(key)
	await frames(2)
	check(fortress.overdrive, "T turns overdrive on")
