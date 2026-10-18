extends GameTest


func test_save_keeps_records_settings_and_daily_bests() -> void:
	check(SaveManager.best_distance() == 0.0 and SaveManager.runs_played() == 0, "a fresh save is empty")
	check(SaveManager.record_run(500.0), "first run is a record")
	check(not SaveManager.record_run(300.0), "a shorter run is not")
	check(SaveManager.best_distance() == 500.0 and SaveManager.runs_played() == 2, "best and run count kept")
	check(SaveManager.record_run(200.0, "2026-10-18"), "first daily run is that day's record")
	check(SaveManager.best_daily("2026-10-18") == 200.0 and SaveManager.best_daily("2026-10-19") == 0.0, "daily bests per date")
	check(SaveManager.best_distance() == 500.0, "a short daily run leaves the overall best alone")
	SaveManager.set_setting("language", "en")
	SaveManager.reload()  # read back from disk
	check(SaveManager.best_distance() == 500.0 and SaveManager.get_setting("language", "vi") == "en", "survives a reload from disk")


func test_daily_mode_uses_the_same_road_for_a_date() -> void:
	Match.queue_run(Match.Mode.DAILY, "2026-10-18")
	var m := await start_match(0)
	check(m.mode == Match.Mode.DAILY and m.daily_date == "2026-10-18", "daily run queued for the date")
	check(m.run_seed == Match.daily_seed("2026-10-18"), "seed comes from the date")
	var route: EndlessRoute = m.get_node("Route")
	route.ensure_ahead(600.0)
	var spot := route.position_at(600.0)
	Match.queue_run(Match.Mode.DAILY, "2026-10-18")
	m = await start_match(0)
	route = m.get_node("Route")
	route.ensure_ahead(600.0)
	check(route.position_at(600.0).distance_to(spot) < 0.001, "same date, same road")
	Match.queue_run(Match.Mode.DAILY, "2026-10-19")
	m = await start_match(0)
	route = m.get_node("Route")
	route.ensure_ahead(600.0)
	check(route.position_at(600.0).distance_to(spot) > 1.0, "another date, another road")


func test_finished_run_is_recorded_and_shown() -> void:
	var m := await start_match()
	var fortress: Fortress = m.get_node("Fortress")
	fortress.storage.add(&"coal", 50)
	await seconds(2.0)
	var hud: Hud = m.get_node("UI/HUD")
	check(hud.get_node("%DistanceLabel").text.ends_with(" m"), "HUD shows the distance: %s" % hud.get_node("%DistanceLabel").text)
	fortress.health.apply_damage(9999.0)
	await frames(1)
	var travelled: float = fortress.follower.distance
	check(SaveManager.best_distance() == travelled, "the run's distance becomes the record")
	var result: ResultScreen = m.get_node("UI/ResultScreen")
	check(result.get_node("%Record").visible, "the result screen celebrates a record")

	m = await start_match()
	m.get_node("Fortress").health.apply_damage(9999.0)
	await frames(1)
	check(not m.get_node("UI/ResultScreen/%Record").visible, "a shorter run is not a record")
	check(SaveManager.best_distance() == travelled, "the record stays")
	check(SaveManager.runs_played() == 2, "both runs counted")


func test_main_scene_waits_on_the_start_menu() -> void:
	var scene: Node = MAIN_SCENE.instantiate()
	tree.root.add_child(scene)
	await frames(2)
	var menu: StartMenu = scene.get_node("Match/UI/StartMenu")
	check(menu.visible and tree.paused, "the game opens on the start menu, paused")
	# The match's own handlers reload the scene, which the harness does not have.
	for sig in [menu.play_requested, menu.daily_requested]:
		for connection in sig.get_connections():
			sig.disconnect(connection.callable)
	var picks := []
	menu.play_requested.connect(func() -> void: picks.append("play"))
	menu.daily_requested.connect(func() -> void: picks.append("daily"))
	menu.get_node("%Play").pressed.emit()
	menu.get_node("%Daily").pressed.emit()
	check(picks == ["play", "daily"], "both buttons report a choice: %s" % [picks])
	tree.paused = false
	scene.free()


func test_meters_are_formatted_with_grouping() -> void:
	check(UiStyle.format_meters(12345.7) == "12.345 m", "got %s" % UiStyle.format_meters(12345.7))
	check(UiStyle.format_meters(980.0) == "980 m", "got %s" % UiStyle.format_meters(980.0))
	check(UiStyle.short_date("2026-10-18") == "18/10", "short date")
