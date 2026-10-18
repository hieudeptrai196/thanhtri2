extends GameTest

const DEFAULT := preload("res://match/difficulty_default.tres")


func test_difficulty_rises_with_distance_and_respects_caps() -> void:
	var d: Difficulty = DEFAULT
	var previous := {"interval": INF, "alive": 0, "health": 0.0, "damage": 0.0, "pack": 0}
	for metres in range(0, 20001, 250):
		var now := {
			"interval": d.spawn_interval(metres), "alive": d.max_alive(metres),
			"health": d.health_multiplier(metres), "damage": d.damage_multiplier(metres), "pack": d.pack_size(metres)}
		check(now.interval <= previous.interval and now.alive >= previous.alive and now.health >= previous.health
			and now.damage >= previous.damage and now.pack >= previous.pack, "never gets easier (at %d m)" % metres)
		previous = now
	check(d.spawn_interval(0) == d.spawn_interval_start and d.max_alive(0) == d.max_alive_start
		and d.health_multiplier(0) == 1.0 and d.pack_size(0) == 1, "starts at the base values")
	check(d.spawn_interval(20000) == d.spawn_interval_min, "interval bottoms out at the minimum")
	check(d.max_alive(20000) == d.max_alive_cap, "alive count is capped")
	check(d.pack_size(20000) == d.pack_size_cap, "wave size is capped")


func test_enemies_far_down_the_road_are_stronger_and_come_in_packs() -> void:
	var m := await start_match()
	var spawner: Spawner = m.get_node("Spawner")
	var follower: RouteFollower = m.get_node("Fortress/RouteFollower")
	var near: Enemy = spawner.spawn_one()
	var base_health: float = near.get_node("Health").max_health
	var base_damage := near.damage
	spawner.clear()
	await frames(1)

	follower.distance = 3000.0  # read by the spawner; the fortress itself stays parked
	follower.base_speed = 0.0
	var far: Enemy = spawner.spawn_one()
	check_near(far.get_node("Health").max_health, base_health * spawner.difficulty.health_multiplier(3000.0), 0.01, "health at 3 km")
	check_near(far.damage, base_damage * spawner.difficulty.damage_multiplier(3000.0), 0.01, "damage at 3 km")
	check(far.get_node("Health").current == far.get_node("Health").max_health, "spawns at full (scaled) health")
	spawner.clear()
	await frames(1)

	spawner.spawn_wave(spawner.difficulty.pack_size(3000.0))
	check(spawner.alive_count() == spawner.difficulty.pack_size(3000.0), "a wave brings a pack of %d" % spawner.difficulty.pack_size(3000.0))


func test_wave_respects_alive_cap() -> void:
	var m := await start_match()
	var spawner: Spawner = m.get_node("Spawner")
	var cap := spawner.difficulty.max_alive(0.0)
	for i in cap:
		spawner.spawn_one()
	spawner.spawn_wave(5)
	check(spawner.alive_count() == cap, "no wave beyond the cap of %d, got %d" % [cap, spawner.alive_count()])
