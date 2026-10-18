extends SceneTree
## Frame-rate benchmark: the real match scene, rendered in a window with vsync off, with growing
## enemy counts crowding the fortress and the player. Prints one row per enemy count.
## Usage: tools/benchmark.sh   (not part of the game build)

const ENEMY_COUNTS: Array[int] = [0, 25, 50, 100, 150, 200, 300]
const WARMUP_FRAMES := 90
const SAMPLE_SECONDS := 4.0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	var scene: Node = load("res://scenes/main.tscn").instantiate()
	var match_node := scene.get_node("Match")
	match_node.rng_seed = 1
	match_node.wait_for_start = false  # skip the start menu
	root.add_child(scene)
	current_scene = scene
	await process_frame

	# Freeze the run so it cannot end mid-measurement: parked fortress, nobody can die.
	var fortress: Fortress = match_node.get_node("Fortress")
	fortress.follower.base_speed = 0.0
	fortress.health.set_max_health(1e9)
	var warrior: Warrior = match_node.get_node("Warrior")
	warrior.health.set_max_health(1e9)
	warrior.global_position = fortress.global_position + Vector3(12, 0.1, 0)
	var spawner: Spawner = match_node.get_node("Spawner")
	spawner.active = false
	spawner.ring_radius = 25.0

	print("Benchmark — %s, %s, window %s" % [
		OS.get_processor_name(), RenderingServer.get_video_adapter_name(), DisplayServer.window_get_size()])
	print("enemies | avg fps | avg ms | worst ms | physics ms | draw calls")
	for count in ENEMY_COUNTS:
		while spawner.alive_count() < count:
			spawner.spawn_one()
		for i in WARMUP_FRAMES:
			await process_frame
		var frames := 0
		var worst_us := 0
		var physics_ms := 0.0
		var draw_calls := 0.0
		var start := Time.get_ticks_usec()
		var last := start
		while Time.get_ticks_usec() - start < SAMPLE_SECONDS * 1e6:
			await process_frame
			var now := Time.get_ticks_usec()
			worst_us = maxi(worst_us, now - last)
			last = now
			frames += 1
			physics_ms += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
			draw_calls += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		var seconds := (last - start) / 1e6
		print("%7d | %7.0f | %6.2f | %8.2f | %10.2f | %10.0f" % [
			spawner.alive_count(), frames / seconds, seconds * 1000.0 / frames, worst_us / 1000.0,
			physics_ms / frames, draw_calls / frames])
	quit()
